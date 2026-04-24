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

## Prerequisites

| Tool       | Version  |
| ---------- | -------- |
| Docker     | 24+      |
| Docker Compose | v2+  |
| Ruby       | 3.3+     |
| Node.js    | 20+      |
| PostgreSQL | 16+ (if running without Docker) |
| Redis      | 7+ (if running without Docker)  |

> **Easiest path:** just install Docker — all other dependencies run inside containers.

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

Three Railway services deploy from this single repo.  
**Recommended builder:** Dockerfile for BE/Worker, Nixpacks for FE.

### 1 — Backend service (web)

```
Root directory: /          (repo root)
Builder:        Dockerfile
Start command:  bundle exec puma -C config/puma.rb
```

| ENV var            | Description                      |
| ------------------ | -------------------------------- |
| `DATABASE_URL`     | Set by Railway PostgreSQL add-on |
| `REDIS_URL`        | Set by Railway Redis add-on      |
| `JWT_SECRET`       | Random secret string             |
| `RAILS_MASTER_KEY` | Contents of `config/master.key`  |
| `FRONTEND_URL`     | FE Railway public URL (for CORS + ActionCable allowed origins) |

### 2 — Worker service (same Dockerfile as BE)

```
Root directory: /          (repo root)
Builder:        Dockerfile
Start command:  bundle exec sidekiq   ← set in Railway UI, not railway.toml
```

> **Important:** The worker's start command must be set in the Railway service **Settings → Deploy → Start Command** in the UI. It is not in `railway.toml` so that it doesn't override the web service.

| ENV var            | Description |
| ------------------ | ----------- |
| `DATABASE_URL`     | Same as BE  |
| `REDIS_URL`        | Same as BE  |
| `JWT_SECRET`       | Same as BE  |
| `RAILS_MASTER_KEY` | Same as BE  |

### 3 — Frontend service (Next.js)

```
Root directory: /frontend
Builder:        Nixpacks
Start command:  npm start
```

Railway automatically sets `PORT=8080`. Make sure the service **Networking → Public domain** maps to port **8080**.

| ENV var    | Description                                                           |
| ---------- | --------------------------------------------------------------------- |
| `API_URL`  | BE Railway **private** URL — used server-side by the API proxy route  |
| `WS_URL`   | BE WebSocket URL (e.g. `wss://myapp-be.up.railway.app`)               |

> **How env vars flow at runtime:**  
> - `API_URL` is read server-side by the Next.js Route Handler (`/api/[...path]`) to proxy all REST calls — never exposed to the browser.  
> - `WS_URL` is read by the Next.js Server Component (`layout.tsx`) at render time and injected as `window.__WS_URL__` so the browser can open a WebSocket directly to the BE.  
> - No `NEXT_PUBLIC_*` vars are needed for a production Railway deployment.

### Watch Paths (optional — prevent unnecessary redeploys)

Configure per service in **Railway UI → Settings → Deploy → Watch Paths**:

| Service  | Watch paths                  |
| -------- | ---------------------------- |
| BE / Worker | `Dockerfile`, `Gemfile*`, `app/**`, `config/**`, `db/**`, `lib/**` |
| Frontend | `frontend/**`                |

---

## Architecture

```
Browser
  └── Next.js FE (local: 3001 / Railway: 8080)
        ├── /api/* → Next.js Route Handler (server-side proxy)
        │               └── Rails BE (local: 3969 / Railway)  → PostgreSQL
        └── WebSocket (window.__WS_URL__)
                └── ActionCable / Rails BE
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
