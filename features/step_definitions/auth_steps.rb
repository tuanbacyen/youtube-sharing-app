Given('I am on the home page') do
  visit '/'
  # Clear any stale localStorage (e.g. auth token from a previous scenario) then
  # reload so React starts with a clean state. Capybara reset_sessions! clears
  # cookies but not localStorage in headless Chrome.
  execute_script("window.localStorage.clear()")
  visit '/'
  expect(page).to have_content('Funny Movies', wait: 10)
end

Given('a user exists with email {string} and password {string}') do |email, password|
  User.create!(email: email, password: password)
end

Given('I am logged in as {string}') do |email|
  User.find_or_create_by!(email: email) { |u| u.password = 'password123' }
  visit '/'
  fill_in 'email', with: email
  fill_in 'password', with: 'password123'
  click_button 'Login / Register'
  expect(page).to have_content("Welcome #{email}")
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I click {string}') do |text|
  click_button text
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end
