# Acceptance feature catalog

These Gherkin files capture user, service-owner, and release-owner outcomes. They are reviewable acceptance criteria; a `.feature` file is only executable when a runner and step definitions connect it to the app or release workflow.

## Automated coverage

- `release_pipeline.feature` is linked to the Ruby acceptance checks in [`test/release_pipeline_test.rb`](../test/release_pipeline_test.rb). The checks exercise the version helper against isolated project copies and inspect release and pull-request workflow structure.
- The multi-page save-and-reopen scenario in [`script_persistence.feature`](../Textream/TestFeatures/macOS/Features/script_persistence.feature) is wired to CucumberSwift in a new macOS XCTest target. It uses the real `TextreamService` file operations and an isolated temporary `.textream` file.
- The Classic reading scenario in [`ios_sessions.feature`](../Textream/TestFeatures/iOS/Features/ios_sessions.feature) is wired to CucumberSwift in the existing iOS XCTest bundle. Its step definitions prepare the real session controller with camera and audio disabled and check authorization state before and after startup. The app, test target, step definitions, and bundled feature resource compiled successfully; simulator execution could not be verified in this environment because CoreSimulator became unavailable.
- The other presenter scenarios are currently stakeholder specifications without executable step definitions. Recording, Photos, networking, PowerPoint import, and update checks need deterministic app seams or controlled service responses before those scenarios can run reliably in CI.

## Run the current checks

```sh
ruby test/release_pipeline_test.rb
xcodebuild test \
  -project Textream/Textream.xcodeproj \
  -scheme Textream \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/textream-macos-derived-data \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
xcodebuild test \
  -project Textream/Textream.xcodeproj \
  -scheme TextreamiOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/textream-derived-data \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

The release suite currently reports the unsafe tag interpolation in the release workflow; this is an intentional failing acceptance check for the planned remediation. The Ruby suite validates shell and workflow boundaries directly. The macOS and iOS Gherkin scenarios are configured to run through CucumberSwift alongside the existing iOS Swift Testing suite. The iOS simulator execution has not yet been confirmed. The wider catalog remains readable without claiming it has been automated.
