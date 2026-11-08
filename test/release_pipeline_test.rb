# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class ReleasePipelineAcceptanceTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  WORKFLOW_PATH = File.join(ROOT, ".github/workflows/release.yml")
  VERSION_HELPER_PATH = File.join(ROOT, ".github/set-macos-marketing-version.rb")
  PROJECT_PATH = File.join(ROOT, "Textream/Textream.xcodeproj/project.pbxproj")

  def setup
    @workflow = File.read(WORKFLOW_PATH)
  end

  def test_release_tag_text_is_never_interpolated_into_a_shell_script
    version_expressions_in_shell = run_scripts.each_with_object([]) do |script, found|
      found.concat(script.scan(/\$\{\{[^\n}]*version\.outputs\.[^}]+\}\}/))
    end

    assert_empty version_expressions_in_shell,
      "Pass release version outputs through step env values, then quote shell variables"
  end

  def test_version_helper_rejects_shell_metacharacters_without_changing_project
    Dir.mktmpdir("textream-release-test") do |directory|
      project_copy = File.join(directory, "project.pbxproj")
      marker_path = File.join(directory, "tag-command-ran")
      original = File.binread(PROJECT_PATH)
      File.binwrite(project_copy, original)
      hostile_version = %(1.2.3"; touch #{marker_path}; #)

      _stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        VERSION_HELPER_PATH,
        hostile_version,
        project_copy
      )

      refute status.success?, "invalid release version should be rejected"
      refute File.exist?(marker_path), "tag text must not execute as a shell command"
      assert_equal original, File.binread(project_copy),
        "rejected tags must leave the project file unchanged"
      assert_includes stderr, "Invalid Apple marketing version"
    end
  end

  def test_valid_version_updates_only_the_macos_marketing_version
    Dir.mktmpdir("textream-release-test") do |directory|
      project_copy = File.join(directory, "project.pbxproj")
      original = File.binread(PROJECT_PATH)
      File.binwrite(project_copy, original)

      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        VERSION_HELPER_PATH,
        "1.2.3",
        project_copy
      )

      assert status.success?, stderr
      assert_includes stdout, "Set macOS Textream marketing version"
      updated = File.binread(project_copy)
      macos_configs = configuration_blocks(updated, "Textream")
      ios_configs = configuration_blocks(updated, "TextreamiOS")
      original_macos_configs = configuration_blocks(original, "Textream")
      original_ios_configs = configuration_blocks(original, "TextreamiOS")

      assert_equal 3, macos_configs.length
      assert macos_configs.all? { |block| block.match?(/^\s*MARKETING_VERSION = 1\.2\.3;$/) }
      assert_equal original_ios_configs, ios_configs,
        "a macOS release must not change the independent iOS version"
      refute_equal original_macos_configs, macos_configs
    end
  end

  def test_public_release_waits_for_successful_validation_and_build
    release_job = @workflow[/^  release:.*?(?=^  [a-zA-Z0-9_-]+:|\z)/m]
    build_job = @workflow[/^  build:.*?(?=^  [a-zA-Z0-9_-]+:|\z)/m]

    refute_nil release_job, "release job must be defined"
    refute_nil build_job, "build job must be defined"
    assert_match(/needs:\s*\[version, build\]/, release_job)
    assert_operator build_job.index("Notarize and validate DMG"), :<,
      build_job.index("Upload DMG artifact")
    assert_includes build_job, "xcrun stapler validate"
    assert_includes build_job, "codesign --verify"
  end

  def test_pull_request_ci_runs_without_release_credentials_or_publication
    ci_path = File.join(ROOT, ".github/workflows/ci.yml")
    assert File.file?(ci_path), "pull-request CI workflow must exist"
    ci = File.read(ci_path)

    assert_match(/^\s+pull_request:/, ci)
    assert_includes ci, "release_pipeline_test.rb"
    assert_includes ci, "xcodebuild test"
    refute_match(/secrets\./, ci, "PR checks must not receive signing credentials")
    refute_match(/action-gh-release|gh release create/i, ci,
      "PR checks must not publish a release")
  end

  def test_release_feature_scenarios_are_linked_to_automated_acceptance_checks
    feature = File.read(File.join(ROOT, "features/release_pipeline.feature"))
    scenario_tests = {
      "Run acceptance checks for a pull request" => :test_pull_request_ci_runs_without_release_credentials_or_publication,
      "Update the macOS version for a valid release tag" => :test_valid_version_updates_only_the_macos_marketing_version,
      "Reject a tag containing shell metacharacters" => :test_version_helper_rejects_shell_metacharacters_without_changing_project,
      "Do not publish an unverified artifact" => :test_public_release_waits_for_successful_validation_and_build
    }
    scenario_titles = feature.scan(/^  Scenario: (.+)$/).flatten

    assert_equal scenario_tests.keys.sort, scenario_titles.sort
    scenario_tests.each do |title, test_method|
      assert self.class.method_defined?(test_method),
        "#{title} must have an automated acceptance check"
    end
  end

  private

  def run_scripts
    scripts = []
    lines = @workflow.lines
    index = 0
    while index < lines.length
      match = lines[index].match(/^(\s*)run:\s*\|\s*$/)
      unless match
        index += 1
        next
      end

      run_indent = match[1].length
      index += 1
      script_lines = []
      while index < lines.length
        line = lines[index]
        indentation = line[/\A */].length
        break if !line.strip.empty? && indentation <= run_indent

        script_lines << line.sub(/\A {#{run_indent + 2}}/, "")
        index += 1
      end
      scripts << script_lines.join
    end
    scripts
  end

  def configuration_blocks(project, name)
    section = project[/\/\* Begin PBXNativeTarget section \*\/.*?\/\* End PBXNativeTarget section \*\//m]
    target = section&.match(/^\s*[0-9A-F]+ \/\* #{Regexp.escape(name)} \*\/ = \{(?<body>.*?)^\s*\};/m)
    configuration_list_id = target&.[](:body)&.match(/buildConfigurationList = ([0-9A-F]+)/)&.[](1)
    lists = project[/\/\* Begin XCConfigurationList section \*\/.*?\/\* End XCConfigurationList section \*\//m]
    list = lists&.match(/^\s*#{Regexp.escape(configuration_list_id.to_s)} \/\*.*?\*\/ = \{(?<body>.*?)^\s*\};/m)
    configuration_ids = list&.[](:body)&.scan(/^\s*([0-9A-F]+) \/\*/)&.flatten || []
    configurations = project[/\/\* Begin XCBuildConfiguration section \*\/.*?\/\* End XCBuildConfiguration section \*\//m]

    configuration_ids.map do |configuration_id|
      configurations.match(
        /^\s*#{Regexp.escape(configuration_id)} \/\*.*?\*\/ = \{(?<body>.*?)^\s*\};/m
      )&.[](:body)
    end
  end
end
