Feature: Real-time Notifications
  As a logged-in user
  I want to receive notifications when others share videos

  @javascript
  Scenario: Receive notification when another user shares a video
    Given user "alice@example.com" exists with password "password123"
    And user "bob@example.com" exists with password "password123"
    And "bob@example.com" is logged in on the main session
    And "alice@example.com" is logged in on a secondary session
    When "alice@example.com" shares "https://www.youtube.com/watch?v=dQw4w9WgXcQ" on the secondary session
    Then "bob@example.com" should see a notification on the main session
