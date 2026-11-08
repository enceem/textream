@macos
Feature: Check for application updates
  As a Textream user
  I want to know when a newer release is available
  So that I can choose whether to download it

  Scenario: Show an available release
    Given the release service reports a newer version
    When Textream checks for updates
    Then the newer version is presented to the user
