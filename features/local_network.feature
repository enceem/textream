@macos
Feature: Share or direct a prompt over the local network
  As a presenter
  I want nearby devices to view or control my prompt
  So that I can use a remote screen or work with a director

  Scenario: View an active prompt through Remote Connection
    Given Remote Connection is enabled and a prompt is active
    When a browser connects on the local network
    Then it can view the prompt and its current progress

  Scenario: Stop Remote Connection
    Given Remote Connection is enabled
    When the presenter disables it
    Then the remote service stops accepting new connections

  Scenario: Reject an unauthorized Director connection
    Given Director Mode is enabled
    When a client connects without a valid token
    Then it cannot change the script or control the prompt

  Scenario: Accept an authorized Director command
    Given Director Mode is enabled
    And a client has authenticated with a valid token
    When it sends a new script
    Then the active prompt uses that script
