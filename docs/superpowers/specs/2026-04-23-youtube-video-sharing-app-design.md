# YouTube Video Sharing App — Design Spec

**Date:** 2026-04-23
**Stack:** Rails 8 + Grape API + React + Vite + ActionCable + Sidekiq + PostgreSQL + Docker
**Deploy target:** Heroku (single app)

---

## 1. Overview

A fullstack web app where authenticated users can share YouTube videos. All logged-in users receive real-time notifications when someone shares a new video.

**Key features:**
- User registration and login (inline in navbar)
- Share YouTube videos via modal popup
- View list of all shared videos on the home page
- Real-time notifications via WebSocket when a new video is shared

---

## 2. Architecture

### Repo structure (monorepo)

```
remitano-2/
├── backend/              # Rails 8 API-only + Grape
├── frontend/             # React + Vite (SPA)
├── docker-compose.yml    # All services
└── docs/
```

### Services

| Service | Tech | Port |
|---|---|---|
| backend | Rails 8 (Puma) | 3000 |
| sidekiq | Sidekiq worker | — |
| frontend | Vite dev server (dev only) | 5173 |
| db | PostgreSQL 16 | 5432 |
| redis | Redis 7 | 6379 |

> **Production:** `vite build` generates static files → copied into `backend/public/` → Puma serves everything. No separate frontend server in production.

### Request flow

```
React SPA (browser)
  │
  ├── HTTP REST → Grape API (/api/v1/...)
  │                  │
  │                  └── on video create → VideoShareNotificationJob.perform_later(video.id)
  │                                           │
  │                                           └── Sidekiq picks up → ActionCable broadcast
  │
  └── WebSocket → ActionCable (/cable)
                    └── NotificationsChannel → push to all subscribed clients
```

---

## 3. API Design (Grape)

Base path: `/api/v1`

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | No | Create user, return JWT |
| POST | `/auth/login` | No | Verify credentials, return JWT |
| DELETE | `/auth/logout` | Yes | Denylist JWT |

### Videos

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/videos` | No | List all videos (newest first) |
| POST | `/videos` | Yes | Share a new YouTube video |

### WebSocket

| Endpoint | Channel | Description |
|---|---|---|
| `/cable` | `NotificationsChannel` | Subscribe to receive new video notifications |

**Notification payload:**
```json
{
  "type": "new_video",
  "title": "Video Title",
  "shared_by": "user@email.com"
}
```

---

## 4. Data Models

### users

| column | type | constraints |
|---|---|---|
| id | bigint PK | |
| email | string | unique, not null |
| password_digest | string | bcrypt, not null |
| created_at | timestamp | |
| updated_at | timestamp | |

### videos

| column | type | constraints |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK | not null, index |
| youtube_url | string | not null |
| youtube_id | string | extracted from URL |
| title | string | fetched from YouTube oEmbed API |
| description | text | fetched from YouTube oEmbed API |
| created_at | timestamp | |
| updated_at | timestamp | |

### jwt_denylists

| column | type | constraints |
|---|---|---|
| id | bigint PK | |
| jti | string | unique, index |
| exp | datetime | for cleanup |

**Notes:**
- No notifications table — notifications are real-time only, not persisted.
- YouTube metadata (title, description) fetched from `https://www.youtube.com/oembed` (free, no API key needed).

---

## 5. Auth Strategy

- **JWT** issued on login/register, expires in 24h.
- Token stored in `localStorage` on the client.
- Sent as `Authorization: Bearer <token>` header on each request.
- Logout denylists the JWT's `jti` in `jwt_denylists` table.
- ActionCable connection authenticated by passing JWT as a query param on connect.

---

## 6. Real-time Notification Flow

1. Authenticated user POSTs YouTube URL to `POST /api/v1/videos`.
2. Grape endpoint validates, fetches YouTube metadata via oEmbed, saves video to DB.
3. On success, enqueues `VideoShareNotificationJob.perform_later(video.id)`.
4. Sidekiq picks up the job.
5. Job calls `ActionCable.server.broadcast("notifications", payload)`.
6. All clients subscribed to `NotificationsChannel` receive the payload.
7. React displays a toast/banner: *"[user@email.com] shared: [Video Title]"*.

---

## 7. Frontend (React + Vite)

### Single page SPA

**Navbar — unauthenticated:**
- Logo "Funny Movies"
- Inline email input + password input + "Login / Register" button

**Navbar — authenticated:**
- Logo "Funny Movies"
- "Welcome [email]"
- "Share a movie" button (opens share modal)
- "Logout" button

**Body:**
- List of `VideoCard` components, newest first
- Each card: YouTube embed/thumbnail, title (red), "Shared by: email", description

**Share Modal (popup):**
- Only openable when authenticated
- Input: YouTube URL
- Button: "Share"
- On success: close modal, video appears in list

**Notification Toast:**
- Top-right banner
- Shows: *"[email] has shared: [title]"*
- Auto-dismiss after ~5 seconds
- Only shown to other logged-in users (not the sharer themselves)

### Components

| Component | Purpose |
|---|---|
| `Navbar` | Auth forms + user controls |
| `VideoList` | Renders list of VideoCard |
| `VideoCard` | Single video with embed + metadata |
| `ShareModal` | YouTube URL input popup |
| `NotificationToast` | Real-time notification banner |
| `useActionCable` | Custom hook, manages WS connection/subscription |
| `useAuth` | Custom hook, manages JWT + user state |

---

## 8. Testing

### Backend (RSpec)

| Type | What to test |
|---|---|
| Model specs | User validations, Video validations, associations |
| Request specs | All Grape endpoints (happy path + error cases) |
| Job specs | `VideoShareNotificationJob` broadcasts correct payload |
| Channel specs | `NotificationsChannel` streams to correct channel |

Tools: RSpec, FactoryBot, Shoulda-Matchers, DatabaseCleaner

### Integration (Cucumber + Capybara)

| Feature | Scenarios |
|---|---|
| User auth | Register new account, login, logout |
| Share video | Open share modal, submit URL, video appears in list |
| Real-time notification | User A shares → User B (in another session) receives notification |

Tools: Cucumber, Capybara, Selenium WebDriver (headless Chrome)

---

## 9. Docker Setup

```yaml
# docker-compose.yml (overview)
services:
  db:        PostgreSQL 16
  redis:     Redis 7
  backend:   Rails 8 (depends on db, redis)
  sidekiq:   Sidekiq (same image as backend, depends on db, redis)
  frontend:  Vite dev server (depends on backend) — dev only
```

- `backend/Dockerfile` — Ruby 3.3, bundle install
- `frontend/Dockerfile` — Node 20, npm install, vite dev server
- `.env.example` with required env vars
- `docker-compose up` to run everything locally in dev mode

---

## 10. Heroku Deployment

Single Heroku app — Vite builds static files, Rails serves them:

**Build step (before deploy):**
```bash
cd frontend && npm run build   # outputs to frontend/dist/
cp -r frontend/dist/. backend/public/
```

**Procfile:**
```
web:    bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
```

**Add-ons:** Heroku Postgres, Heroku Redis

**ENV vars:** `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `RAILS_MASTER_KEY`

> The build step is automated via a `bin/build` script triggered by Heroku's Ruby buildpack `postinstall` hook or a custom buildpack ordering (Node.js buildpack first, then Ruby).

---

## 11. Out of Scope

- Up/down votes (shown in wireframe but spec says "no need to display")
- Video search or filtering
- Admin roles
- Email verification
- Notification history / persistence in DB
