@macos
Feature: Read a script on Mac
  As a presenter
  I want to control a prompt while speaking
  So that I can deliver a script at my own pace

  Scenario: Start Classic mode without microphone access
    Given a presenter has entered a script and selected Classic mode
    When they start the prompt
    Then the prompt begins at the current reading position
    And microphone and speech permissions are not requested

  Scenario: Pause and resume a Classic prompt
    Given a Classic prompt is moving through a script
    When the presenter pauses and resumes it
    Then the prompt remains at the same reading position while paused
    And continues from there after resuming

  Scenario: Follow recognized speech
    Given the presenter has granted speech permission
    And Word Tracking is selected
    When recognized speech matches the script
    Then the matching words are highlighted as reading advances

  Scenario: Pause Voice-Activated mode during silence
    Given Voice-Activated mode is running
    When the presenter becomes silent and then speaks again
    Then scrolling pauses during silence and resumes with speech
