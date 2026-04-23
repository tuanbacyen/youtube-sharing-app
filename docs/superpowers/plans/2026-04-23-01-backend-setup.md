# Plan 1: Backend Setup

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Initialize Rails 8 API project with all gems, config, and RSpec ready to write tests.

**Architecture:** Rails 8 API-only app initialized at the project root. `frontend/` subfolder holds the React + Vite SPA. Grape for REST API. Sidekiq + Redis for background jobs. ActionCable for WebSocket. PostgreSQL for data. No application code yet — only project skeleton and config.

**Tech Stack:** Ruby 3.3, Rails 8, Grape, jwt, bcrypt, Sidekiq 7, Redis 5, PostgreSQL 16, RSpec 6, FactoryBot, Shoulda-Matchers, WebMock, Cucumber, Capybara, Selenium WebDriver

**Next plan:** [02 — Models & Services](2026-04-23-02-models-services.md)

---

## Task 1: Generate Rails 8 API project

**Files:**
- Create: `Gemfile` (Rails project at repo root)

- [ ] **Step 1: Generate Rails 8 API app at the project root**

```bash
cd /Users/pat/Desktop/my-project/interview-project/remitano-2
rails new . --api --database=postgresql --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-active-storage --skip-hotwire
```

> `rails new .` initializes Rails in the current directory. The existing `docs/` folder will not be overwritten. If Rails prompts to overwrite any existing file, type `n` to skip.

Expected: Rails 8 files created at repo root (`app/`, `config/`, `db/`, `Gemfile`, etc.)

- [ ] **Step 2: Replace Gemfile**

`Gemfile`:
```ruby
source 'https://rubygems.org'
ruby '3.3.0'

gem 'rails', '~> 8.0'
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rack-cors'

gem 'grape'
gem 'jwt'
gem 'bcrypt', '~> 3.1'
gem 'sidekiq', '~> 7.0'
gem 'redis', '~> 5.0'

group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'database_cleaner-active_record'
  gem 'webmock'
end

group :test do
  gem 'cucumber-rails', require: false
  gem 'capybara'
  gem 'selenium-webdriver'
end

group :development do
  gem 'debug'
end
```

- [ ] **Step 3: Install gems**

```bash
bundle install
```

Expected: All gems installed without errors

---

## Task 2: Configure Rails

**Files:**
- Modify: `config/application.rb`
- Create: `config/initializers/cors.rb`
- Create: `config/initializers/sidekiq.rb`
- Modify: `config/cable.yml`
- Modify: `config/database.yml`

- [ ] **Step 1: Add Sidekiq as queue adapter**

In `config/application.rb`, add inside the `Application` class body:
```ruby
config.active_job.queue_adapter = :sidekiq
```

- [ ] **Step 2: Create CORS initializer**

`config/initializers/cors.rb`:
```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

- [ ] **Step 3: Create Sidekiq initializer**

`config/initializers/sidekiq.rb`:
```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
```

- [ ] **Step 4: Configure cable.yml**

`config/cable.yml`:
```yaml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>

test:
  adapter: async

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: remitano_production
```

> `async` (not `test`) is required for Cucumber — the `:test` adapter is in-memory only and cannot handle real browser WebSocket connections.

- [ ] **Step 5: Configure database.yml**

`config/database.yml`:
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  url: <%= ENV.fetch("DATABASE_URL", "postgres://localhost/remitano_development") %>

test:
  <<: *default
  url: <%= ENV.fetch("DATABASE_URL", "postgres://localhost/remitano_test") %>

production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

---

## Task 3: Install RSpec and configure

**Files:**
- Modify: `spec/rails_helper.rb`
- Modify: `spec/spec_helper.rb`

- [ ] **Step 1: Install RSpec**

```bash
bundle exec rails generate rspec:install
```

Expected: `spec/spec_helper.rb` and `spec/rails_helper.rb` created

- [ ] **Step 2: Configure rails_helper.rb**

Add after the existing `require` lines at the top of `spec/rails_helper.rb`:
```ruby
require 'factory_bot_rails'
require 'shoulda/matchers'
require 'webmock/rspec'
```

Add inside the `RSpec.configure do |config|` block:
```ruby
config.include FactoryBot::Syntax::Methods

config.before(:suite) do
  DatabaseCleaner.strategy = :transaction
  DatabaseCleaner.clean_with(:truncation)
end

config.around(:each) do |example|
  DatabaseCleaner.cleaning { example.run }
end
```

Add after the `RSpec.configure` block:
```ruby
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

- [ ] **Step 3: Create databases and run an empty test to verify setup**

```bash
bundle exec rails db:create
bundle exec rspec --dry-run
```

Expected: Databases created, RSpec runs with 0 examples

- [ ] **Step 4: Initialize git and commit**

```bash
git init
git add .
git commit -m "feat: initialize Rails 8 API project with Grape, JWT, Sidekiq, RSpec"
```
