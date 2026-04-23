Feature: Share YouTube Video
  As a logged-in user
  I want to share a YouTube video
  So that others can watch it

  Scenario: Share a video successfully
    Given I am logged in as "sharer@example.com"
    When I click "Share a movie"
    And I fill in "Youtube URL" with "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    And I click "Share"
    Then I should see a video in the list

  Scenario: Cannot share without logging in
    Given I am on the home page
    Then I should not see "Share a movie"
