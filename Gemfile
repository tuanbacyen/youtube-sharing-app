source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
ruby '3.2.2'
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
gem "rack-cors"
gem "grape"
gem "grape-entity"
gem "jwt"
gem "bcrypt", "~> 3.1"
gem "sidekiq", "~> 7.0"
gem "redis", "~> 5.0"

group :development, :test do
  gem 'brakeman', require: false      # Security analysis
  gem 'debug', '~> 1.11.1', platforms: %i[mri windows]
  gem 'pry-byebug'                    # Debugging
  gem 'rubocop-rails-omakase', require: false # Style checking
end

group :development do
  gem 'erb_lint', require: false        # ERB template linting
  gem 'lefthook', require: false        # Git hooks manager
  gem 'letter_opener' # Email preview
  gem 'rubocop-capybara', require: false  # Capybara-specific linting
  gem 'rubocop-factory_bot', require: false  # FactoryBot linting
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'web-console'
end

group :test do
  # Testing Framework
  gem 'faker'
  gem 'factory_bot_rails'
  gem 'rspec-json_expectations'
  gem 'rspec-rails'
  gem 'rspec-sidekiq', require: false  # prevent auto-require from faking Sidekiq in Cucumber
  gem 'shoulda-matchers'

  # JUnit XML for test timing analysis
  gem 'rspec_junit_formatter'

  # Test Utilities
  gem 'capybara'                      # Integration testing
  gem 'capybara-select-2', github: 'Hirurg103/capybara_select2'  # Select2 testing support
  gem 'selenium-webdriver'            # Selenium driver for Capybara

  # Cucumber for BDD acceptance testing
  gem 'cucumber-rails', '~> 4.0', require: false
  gem 'cucumber'
  gem 'database_cleaner-active_record'              # Clean test database
  # Kafka testing without server
  gem 'pg_query', '~> 6.1.0'                      # Query analysis
  gem 'prosopite'                     # N+1 query detection
  gem 'webmock' # HTTP request stubbing
end
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"
