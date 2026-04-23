Then('I should see a video in the list') do
  expect(page).to have_css('iframe[src*="youtube.com/embed"]')
end
