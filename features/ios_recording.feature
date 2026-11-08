@ios
Feature: Record a prompt on iPhone or iPad
  As a presenter
  I want to capture a performance while reading
  So that I can save and review the finished video

  Scenario: Save a completed recording
    Given the presenter has granted recording permissions
    When they finish a recording
    Then the video is saved to Photos and appears in the recordings gallery

  Scenario: Keep the prompt out of the recorded video
    Given the presenter is recording with the prompt visible
    When the video is saved
    Then the saved video does not contain the prompt overlay

  Scenario: Recover from a failed Photos save
    Given a completed recording could not be saved to Photos
    When the presenter chooses retry
    Then Textream attempts to save the retained recording again
