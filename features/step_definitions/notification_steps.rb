Given('user {string} exists with password {string}') do |email, password|
  User.find_or_create_by!(email: email) { |u| u.password = password }
end

Given('{string} is logged in on the main session') do |email|
  Capybara.using_session(:main) do
    visit '/'
    fill_in 'email', with: email
    fill_in 'password', with: 'password123'
    click_button 'Login / Register'
    expect(page).to have_content("Welcome #{email}")
  end
end

Given('{string} is logged in on a secondary session') do |email|
  Capybara.using_session(:secondary) do
    visit '/'
    fill_in 'email', with: email
    fill_in 'password', with: 'password123'
    click_button 'Login / Register'
    expect(page).to have_content("Welcome #{email}")
  end
end

When('{string} shares {string} on the secondary session') do |_email, url|
  Capybara.using_session(:secondary) do
    click_button 'Share a movie'
    fill_in 'Youtube URL', with: url
    click_button 'Share'
  end
end

Then('{string} should see a notification on the main session') do |_email|
  Capybara.using_session(:main) do
    expect(page).to have_css('[data-testid="notification-toast"]', wait: 10)
  end
end
