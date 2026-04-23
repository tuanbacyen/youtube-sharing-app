# Plan 6: Docker + Cucumber + Deployment

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Docker Compose for local dev, Cucumber integration tests for full-stack flows, Heroku deployment config, and a complete README.

**Architecture:** Docker Compose runs 5 services (db, redis, backend, sidekiq, frontend). The `backend` and `sidekiq` services build from the repo root (`.`) where Rails lives. The `frontend` service builds from `./frontend/` (subfolder inside the Rails root). Cucumber tests use Capybara + headless Chrome against the built React SPA served by Rails from `public/`. A `bin/build` script builds the frontend (`frontend/dist/`) and copies it to `public/` for both Heroku and Cucumber.

> **Directory layout reminder:**
> ```
> remitano-2/          ← repo root = Rails root
> ├── Dockerfile       ← builds Rails app (excludes frontend/ via .dockerignore)
> ├── frontend/        ← React + Vite (has its own Dockerfile)
> │   ├── dist/        ← Vite build output
> │   └── Dockerfile
> ├── public/          ← where frontend/dist/ is copied for Rails to serve
> └── docker-compose.yml
> ```

**Tech Stack:** Docker, Docker Compose, Cucumber-Rails, Capybara, Selenium WebDriver (headless Chrome), Heroku

**Previous plan:** [05 — Frontend](2026-04-23-05-frontend.md)

---

## Task 1: Docker setup

**Files:**
- Create: `Dockerfile`
- Create: `frontend/Dockerfile`
- Create: `.dockerignore`
- Create: `docker-compose.yml`
- Create: `.env.example`

- [ ] **Step 1: Create root Dockerfile (Rails app)**

`Dockerfile`:
```dockerfile
FROM ruby:3.3-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

- [ ] **Step 2: Create .dockerignore**

`.dockerignore`:
```
frontend/
docs/
node_modules/
.git/
log/
tmp/
spec/
features/
```

- [ ] **Step 3: Create frontend Dockerfile**

`frontend/Dockerfile`:
```dockerfile
FROM node:20-slim

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host"]
```

- [ ] **Step 4: Create docker-compose.yml**

`docker-compose.yml` (at repo root):
```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: remitano_development
    ports:
      - '5432:5432'
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 5s
      timeout: 5s
      retries: 5

  backend:
    build: .
    command: bundle exec puma -C config/puma.rb
    volumes:
      - .:/app
      - /app/frontend
    ports:
      - '3000:3000'
    environment:
      DATABASE_URL: postgres://postgres:password@db:5432/remitano_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
      FRONTEND_URL: http://localhost:5173
      JWT_SECRET: ${JWT_SECRET:-devsecret}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  sidekiq:
    build: .
    command: bundle exec sidekiq
    volumes:
      - .:/app
      - /app/frontend
    environment:
      DATABASE_URL: postgres://postgres:password@db:5432/remitano_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
      JWT_SECRET: ${JWT_SECRET:-devsecret}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  frontend:
    build: ./frontend
    volumes:
      - ./frontend:/app
      - /app/node_modules
    ports:
      - '5173:5173'
    depends_on:
      - backend

volumes:
  postgres_data:
```

- [ ] **Step 5: Create .env.example**

`.env.example`:
```
DATABASE_URL=postgres://postgres:password@localhost:5432/remitano_development
REDIS_URL=redis://localhost:6379/0
JWT_SECRET=change_me_in_production
RAILS_MASTER_KEY=
FRONTEND_URL=http://localhost:5173
```

- [ ] **Step 6: Build and start Docker**

```bash
docker compose up --build
```

Expected: All 5 services start without errors

- [ ] **Step 7: Run migrations inside Docker**

```bash
docker compose exec backend bundle exec rails db:create db:migrate
```

Expected: Tables created in Dockerized PostgreSQL

- [ ] **Step 8: Commit**

```bash
git add . && git commit -m "feat: add Docker Compose setup for all 5 services"
```

---

## Task 2: Cucumber integration tests

**Files:**
- Modify: `features/support/env.rb`
- Create: `features/support/helpers.rb`
- Create: `features/step_definitions/auth_steps.rb`
- Create: `features/step_definitions/video_steps.rb`
- Create: `features/step_definitions/notification_steps.rb`
- Create: `features/auth.feature`
- Create: `features/share_video.feature`
- Create: `features/notifications.feature`

- [ ] **Step 1: Install Cucumber boilerplate**

```bash
bundle exec rails generate cucumber:install
```

Expected: `features/support/env.rb` and `features/step_definitions/` created

- [ ] **Step 2: Configure env.rb with Capybara + headless Chrome**

`features/support/env.rb`:
```ruby
require 'cucumber/rails'
require 'capybara/cucumber'
require 'selenium-webdriver'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1280,800')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :headless_chrome
Capybara.javascript_driver = :headless_chrome
Capybara.default_max_wait_time = 10
Capybara.app = Rails.application

ActionController::Base.allow_forgery_protection = false
```

- [ ] **Step 3: Create DatabaseCleaner helpers**

`features/support/helpers.rb`:
```ruby
require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :truncation

Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
end
```

- [ ] **Step 4: Write auth.feature**

`features/auth.feature`:
```gherkin
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
```

- [ ] **Step 5: Write share_video.feature**

`features/share_video.feature`:
```gherkin
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
```

- [ ] **Step 6: Write notifications.feature**

`features/notifications.feature`:
```gherkin
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
```

- [ ] **Step 7: Write auth step definitions**

`features/step_definitions/auth_steps.rb`:
```ruby
Given('I am on the home page') do
  visit '/'
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
```

- [ ] **Step 8: Write video step definitions**

`features/step_definitions/video_steps.rb`:
```ruby
Then('I should see a video in the list') do
  expect(page).to have_css('iframe[src*="youtube.com/embed"]')
end
```

- [ ] **Step 9: Write notification step definitions**

`features/step_definitions/notification_steps.rb`:
```ruby
Given('{string} exists with password {string}') do |email, password|
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
```

- [ ] **Step 10: Build frontend (Cucumber hits the built SPA served by Rails)**

Run from repo root:
```bash
cd frontend && npm run build
cd ..
cp -r frontend/dist/. public/
```

Expected: `public/index.html` and `public/assets/` present at repo root

- [ ] **Step 11: Run Cucumber tests**

```bash
bundle exec cucumber
```

Expected: All scenarios pass

- [ ] **Step 12: Commit**

```bash
git add . && git commit -m "feat: add Cucumber integration tests for auth, share video, and real-time notifications"
```

---

## Task 3: Heroku deployment config + build script + README

**Files:**
- Create: `Procfile`
- Create: `bin/build`
- Create: `README.md`

- [ ] **Step 1: Create Procfile**

`Procfile`:
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
```

- [ ] **Step 2: Create bin/build script**

`bin/build`:
```bash
#!/usr/bin/env bash
set -e

echo "==> Building frontend..."
cd frontend
npm install
npm run build
cd ..

echo "==> Copying build to public/..."
rm -rf public/assets public/index.html
cp -r frontend/dist/. public/

echo "==> Done."
echo "Deploy: git push heroku main"
echo "Required Heroku ENV vars: DATABASE_URL, REDIS_URL, JWT_SECRET, RAILS_MASTER_KEY, RAILS_SERVE_STATIC_FILES=1"
```

```bash
chmod +x bin/build
```

- [ ] **Step 3: Verify build script**

```bash
./bin/build
ls public/
```

Expected: `index.html` and `assets/` present in `public/`

- [ ] **Step 4: Create README.md**

`README.md`:
```markdown
# Funny Movies — YouTube Video Sharing App

## Introduction

A fullstack web app for sharing YouTube videos with real-time notifications.
Built with Ruby on Rails 8 (Grape API + ActionCable + Sidekiq) and React + Vite.

**Features:** User registration/login · Share YouTube videos · Real-time notifications

## Prerequisites

- Ruby 3.3 · Node.js 20 · PostgreSQL 16 · Redis 7
- Chrome (for Cucumber tests)
- Docker + Docker Compose (optional)

## Installation & Configuration

```bash
git clone <repo-url> && cd remitano-2
cp .env.example .env
# Set JWT_SECRET and RAILS_MASTER_KEY in .env
```

## Database Setup

```bash
bundle install
bundle exec rails db:create db:migrate
```

## Running the Application

### Without Docker

```bash
# Terminal 1 — Rails backend (port 3000)
bundle exec rails server

# Terminal 2 — Sidekiq worker
bundle exec sidekiq

# Terminal 3 — Vite dev server (port 5173)
cd frontend && npm install && npm run dev
```

Open http://localhost:5173

### With Docker

```bash
docker compose up --build
docker compose exec backend bundle exec rails db:create db:migrate
```

Open http://localhost:5173

## Running Tests

### Unit + Request tests (RSpec)

```bash
bundle exec rspec
```

### Integration tests (Cucumber)

Build the frontend first — Cucumber tests the built SPA served by Rails:

```bash
./bin/build
bundle exec cucumber
```

## Heroku Deployment

```bash
# Build frontend into public/ first
./bin/build

# Deploy to Heroku
git push heroku main
```

Required Heroku ENV vars:
- `DATABASE_URL` — set by Heroku Postgres add-on
- `REDIS_URL` — set by Heroku Redis add-on
- `JWT_SECRET` — random secret string
- `RAILS_MASTER_KEY` — from `config/master.key`
- `RAILS_SERVE_STATIC_FILES=1` — required for Rails to serve the React SPA

## Usage

1. Enter email + password in the navbar → click **Login / Register** (auto-registers if new)
2. Click **Share a movie** → paste a YouTube URL → click **Share**
3. Other logged-in users will see a real-time notification banner (top-right)
4. The video list updates automatically for all users

## Troubleshooting

| Problem | Solution |
|---|---|
| Database connection error | Ensure PostgreSQL is running, check `DATABASE_URL` |
| Redis connection error | Ensure Redis is running, check `REDIS_URL` |
| No real-time notifications | Check Sidekiq is running, check `REDIS_URL` |
| WebSocket not connecting | Check `JWT_SECRET` env var, restart Rails |
| Cucumber tests fail | Run `./bin/build` before `bundle exec cucumber` |
| "Could not fetch YouTube video info" | URL must be `youtube.com/watch?v=` or `youtu.be/` format |
```

- [ ] **Step 5: Final commit**

```bash
git add . && git commit -m "feat: add Procfile, bin/build script, and complete README"
```

- [ ] **Step 6: Run full RSpec suite one last time**

```bash
bundle exec rspec
```

Expected: All examples pass with 0 failures
