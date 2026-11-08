@macos
Feature: Reuse scripts and presentation notes
  As a presenter
  I want to save scripts and import presentation notes
  So that I can prepare prompts from my existing material

  Scenario: Save and reopen a multi-page script
    Given a script contains multiple pages
    When the presenter saves and reopens it as a .textream file
    Then the page text and order are preserved

  Scenario: Import PowerPoint presenter notes
    Given a valid PowerPoint file contains presenter notes
    When the presenter imports it
    Then the notes become prompt pages in slide order

  Scenario: Reject a malformed PowerPoint file
    Given the presenter has an existing script
    And a selected PowerPoint file is malformed
    When the presenter imports it
    Then Textream reports the import error
