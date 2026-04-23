# Funny Movies — YouTube Video Sharing App

## Introduction

A fullstack web app for sharing YouTube videos with real-time notifications.
Built with Ruby on Rails 8 (Grape API + ActionCable + Sidekiq) and React + Vite.

**Features:** User registration/login · Share YouTube videos · Real-time notifications via WebSocket

## Prerequisites

- Ruby 3.2.2 · Node.js 20 · PostgreSQL 16 · Redis 7
- Chrome (for Cucumber integration tests)
- Docker + Docker Compose (optional)

## Installation & Configuration

```bash
git clone <repo-url> && cd remitano-2
cp .env.example .env
# Edit .env: set JWT_SECRET and RAILS_MASTER_KEY
```

## Database Setup

```bash
bundle install
bundle exec rails db:create db:migrate
```

## Running the Application

### Without Docker

```bash
# Terminal 1 — Rails backend (port 3969)
bundle exec rails server -p 3969

# Terminal 2 — Sidekiq worker
bundle exec sidekiq

# Terminal 3 — Vite dev server (port 3001)
cd frontend && npm install && npm run dev
```

Open http://localhost:3001

### With Docker

```bash
docker compose up --build
docker compose exec backend bundle exec rails db:create db:migrate
```

Open http://localhost:3001

## Running Tests

### Unit + Request tests (RSpec)

```bash
bundle exec rspec
```

### Integration tests (Cucumber)

```bash
# Option A — let the script manage servers automatically
bin/run_cucumber_tests

# Option B — bring up servers yourself, then run
# Terminal 1: RAILS_ENV=test bundle exec rails server -p 3969
# Terminal 2: RAILS_ENV=test bundle exec sidekiq
# Terminal 3: cd frontend && npm run dev
RAILS_ENV=test FE_URL=http://localhost:3001 bundle exec cucumber
```

Screenshots of failing scenarios are saved to `tmp/screenshots/`.

## Deployment (Railway / Heroku)

```bash
# Build frontend into public/ first
./bin/build

# Push to Railway
railway up

# Or push to Heroku
git push heroku main
```

Required ENV vars:
| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection URL |
| `REDIS_URL` | Redis connection URL |
| `JWT_SECRET` | Random secret string |
| `RAILS_MASTER_KEY` | Contents of `config/master.key` |
| `RAILS_SERVE_STATIC_FILES` | Set to `1` for Rails to serve the React SPA |
| `FRONTEND_URL` | FE origin for CORS (e.g. `https://myapp.railway.app`) |

## Usage

1. Enter email + password in the navbar → click **Login / Register** (auto-registers if new)
2. Click **Share a movie** → paste a YouTube URL → click **Share**
3. Other logged-in users will see a real-time notification banner (top-right)
4. The video list updates automatically for all users

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Browser                                            │
│  React + Vite (port 3001)                           │
│  ├── /api/*  ──proxy──► Rails Grape API (port 3969) │
│  └── /cable  ──ws───►  ActionCable (port 3969)      │
└─────────────────────────────────────────────────────┘
                    │
            ┌───────┴────────┐
            ▼                ▼
       PostgreSQL          Redis
                             │
                         Sidekiq
                    (broadcast jobs)
```

## Troubleshooting

| Problem | Solution |
|---|---|
| Database connection error | Ensure PostgreSQL is running, check `DATABASE_URL` |
| Redis connection error | Ensure Redis is running, check `REDIS_URL` |
| No real-time notifications | Check Sidekiq is running, check `REDIS_URL` |
| WebSocket not connecting | Check `JWT_SECRET` env var, restart Rails |
| Cucumber tests fail | Run `./bin/build` then `bin/run_cucumber_tests` |
| "Could not fetch YouTube video info" | URL must be `youtube.com/watch?v=` or `youtu.be/` format |
