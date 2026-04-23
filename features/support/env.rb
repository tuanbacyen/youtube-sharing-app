require 'cucumber/rails'
require 'capybara/cucumber'
require 'selenium-webdriver'

# Test against real running servers (FE + BE).
# Use bin/run_cucumber_tests to start test servers and run cucumber.
Capybara.run_server = false
Capybara.app_host = ENV.fetch("FE_URL", "http://localhost:3001")

Capybara.register_driver :headless_chrome do |_app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1280,800')
  Capybara::Selenium::Driver.new(nil, browser: :chrome, options: options)
end

Capybara.default_driver    = :headless_chrome
Capybara.javascript_driver = :headless_chrome
Capybara.default_max_wait_time = 15
