Feature: User Authentication
  As a visitor
  I want to register and login
  So that I can share YouTube videos

  Scenario: Register a new account
    Given I am on the home page
    When I fill in "email" with "newuser@example.com"
    And I fill in "password" with "password123"
    And I click "Login / Register"
    Then I should see "Welcome newuser@example.com"

  Scenario: Login with existing credentials
    Given a user exists with email "existing@example.com" and password "password123"
    And I am on the home page
    When I fill in "email" with "existing@example.com"
    And I fill in "password" with "password123"
    And I click "Login / Register"
    Then I should see "Welcome existing@example.com"

  Scenario: Logout
    Given I am logged in as "user@example.com"
    When I click "Logout"
    Then I should see "Login / Register"
    And I should not see "Share a movie"
