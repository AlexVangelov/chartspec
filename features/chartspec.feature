Feature: Chartspec
  @chart
  Scenario: Chartspec passed feature
    Given I have a feature
    When I run the feature
    And there is no errors
    Then the feature should pass
  
  Scenario: Chartspec pending feature
    Given I have a feature
    When I run the feature
    And there is no defined steps
    Then the feature should be pending
    
  Scenario: Chartspec failed feature
    Given I have a feature
    When I run the feature
    And there is an error
    Then the feature should fail
    And the backtrace should be visible