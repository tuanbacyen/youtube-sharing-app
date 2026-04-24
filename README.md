# Funny Movies — YouTube Video Sharing App

## Introduction

A fullstack web app for sharing YouTube videos with real-time notifications.

| Layer         | Stack                                               |
| ------------- | --------------------------------------------------- |
| Backend (BE)  | Ruby on Rails 8 · Grape API · ActionCable · Sidekiq |
| Frontend (FE) | Next.js (separate service)                          |
| Queue         | Sidekiq + Redis                                     |
| Database      | PostgreSQL                                          |

**Features:** User registration/login · Share YouTube videos · Real-time WebSocket notifications

---

## Quick Start (Docker)

```bash
bin/install    # build Docker images (first-time setup)
bin/dev        # start all services + run migrations
```

Open http://localhost:3001 (FE) · http://localhost:3969 (BE API)

When done:

```bash
bin/stop           # stop everything, keep data
bin/stop --volumes # stop everything and wipe all data
```

---

## All Commands

| Command                                | Description                                                        |
| -------------------------------------- | ------------------------------------------------------------------ |
| `bin/install`                          | Build Docker images (first-time setup)                             |
| `bin/dev`                              | Start all services in foreground (db, redis, BE, Sidekiq, FE)      |
| `bin/dev --background` or `bin/dev -d` | Same as above but detached (no log output)                         |
| `bin/stop`                             | Stop dev + test environments, keep volumes                         |
| `bin/stop --volumes`                   | Stop dev + test environments and remove all volumes                |
| `bin/unit_test`                        | Run RSpec unit/request tests inside Docker                         |
| `bin/cucumber_start`                   | Start (or reset) isolated Docker test environment                  |
| `bin/cucumber_test`                    | Run all Cucumber integration tests against the test environment    |
| `bin/cucumber_test <file>`             | Run a specific feature file, e.g. `features/notifications.feature` |

---

## Manual Setup (without Docker)

```bash
# Dependencies
bundle install
cd frontend && npm install && cd ..

# Database
bundle exec rails db:create db:migrate

# Start services (4 terminals)
RAILS_ENV=development bundle exec rails server -p 3969   # BE
RAILS_ENV=development bundle exec sidekiq                # Worker
cd frontend && npm run dev                               # FE (port 3001)
```

---

## Running Tests

### Unit tests (RSpec)

```bash
bin/unit_test              # via Docker (recommended)
# or locally:
bundle exec rspec
```

### Integration tests (Cucumber)

The test environment runs in its **own isolated Docker stack** on separate ports
(BE: 3669, FE: 3100) so it never conflicts with a running dev environment.

```bash
# Step 1 — start (or reset) the test environment
bin/cucumber_start

# Step 2 — run all tests (or a specific feature)
bin/cucumber_test
bin/cucumber_test features/notifications.feature

# To reset the environment between runs, just call bin/cucumber_start again.
```

Screenshots of failing scenarios → `tmp/screenshots/`

---

## Deployment (Railway)

Two separate Railway services:

### Backend service

```
Start command: bundle exec puma -C config/puma.rb
```

| ENV var            | Description                      |
| ------------------ | -------------------------------- |
| `DATABASE_URL`     | Set by Railway PostgreSQL add-on |
| `REDIS_URL`        | Set by Railway Redis add-on      |
| `JWT_SECRET`       | Random secret string             |
| `RAILS_MASTER_KEY` | Contents of `config/master.key`  |
| `FRONTEND_URL`     | FE Railway URL (for CORS)        |

### Worker service (same Docker image as BE)

```
Start command: bundle exec sidekiq
```

| ENV var            | Description |
| ------------------ | ----------- |
| `DATABASE_URL`     | Same as BE  |
| `REDIS_URL`        | Same as BE  |
| `JWT_SECRET`       | Same as BE  |
| `RAILS_MASTER_KEY` | Same as BE  |

### Frontend service (Next.js)

```
Start command: npm start
Build command: npm run build
```

| ENV var               | Description                                             |
| --------------------- | ------------------------------------------------------- |
| `NEXT_PUBLIC_API_URL` | BE Railway URL (e.g. `https://myapp-be.up.railway.app`) |
| `NEXT_PUBLIC_WS_URL`  | WebSocket URL (e.g. `wss://myapp-be.up.railway.app`)    |

---

## Architecture

```
Browser
  └── Next.js FE (port 3001 / Railway)
        ├── REST  → Rails BE (port 3969 / Railway)  → PostgreSQL
        └── WS    → ActionCable (Rails BE)
                        └── Sidekiq ← Redis
```

---

## Usage

1. Enter email + password → click **Login / Register** (auto-registers if new)
2. Click **Share a movie** → paste a YouTube URL → click **Share**
3. Other logged-in users see a real-time notification banner (top-right)

---

## Troubleshooting

| Problem                    | Solution                                                              |
| -------------------------- | --------------------------------------------------------------------- |
| Database connection error  | Check `DATABASE_URL`, ensure PostgreSQL is running                    |
| Redis / WebSocket error    | Check `REDIS_URL`, ensure Redis + Sidekiq are running                 |
| No real-time notifications | Sidekiq not running or `REDIS_URL` wrong                              |
| CORS errors on FE          | Set `FRONTEND_URL` on BE to match FE origin                           |
| Cucumber tests fail        | Run `bin/cucumber_start` first, then `bin/cucumber_test`              |
| Port conflicts             | Dev uses 3969/3001, test uses 3669/3100 — they can run simultaneously |
