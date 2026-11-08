@devops
Feature: Validate and publish releases safely
  As a release owner
  I want tags and build artifacts validated before publication
  So that a release cannot execute tag text or publish an unverified build

  Scenario: Run acceptance checks for a pull request
    Given a pull request changes the app or release configuration
    When CI runs
    Then macOS and iOS acceptance suites run
    And release signing credentials and publication are not used

  Scenario: Update the macOS version for a valid release tag
    Given a valid version tag such as "v1.2.3"
    When release validation succeeds
    Then only the macOS app marketing version is updated

  Scenario: Reject a tag containing shell metacharacters
    Given a release tag contains invalid version text and shell metacharacters
    When release validation runs
    Then the release is rejected before project files or release artifacts are changed
    And no command from the tag is executed

  Scenario: Do not publish an unverified artifact
    Given signing, notarization, or artifact validation fails
    When the release workflow completes
    Then no public release is published
