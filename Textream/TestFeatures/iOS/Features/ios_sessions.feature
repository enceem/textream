@ios
Feature: Read and record on iPhone or iPad
  As a presenter
  I want to read or record a script on my device
  So that I can present hands-free and keep a usable recording

  Scenario: Start Classic reading without camera or microphone access
    Given the presenter is in Read mode with the camera disabled and Classic selected
    When they start the prompt
    Then the prompt starts at the beginning of the script
    And camera, microphone, and speech access remain unrequested
