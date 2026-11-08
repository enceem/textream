@macos
Feature: Reuse a saved script
  As a presenter
  I want to save and reopen a script with multiple pages
  So that I can continue preparing without losing page content or order

  Scenario: Save and reopen a multi-page script
    Given the presenter has a two-page script
    When they save and reopen the script
    Then both page texts and their order are preserved
