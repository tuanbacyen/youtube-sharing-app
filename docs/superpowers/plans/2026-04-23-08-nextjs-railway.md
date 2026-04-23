# Plan 8: Next.js Frontend + Railway Deployment

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace Vite React SPA with a Next.js app (separate service). Deploy BE + Worker + FE to Railway as 3 independent services. Update Docker Compose and Cucumber tests accordingly.

**Architecture:**
```
Railway
  ├── be-service      → Rails API (Puma) — DATABASE_URL, REDIS_URL
  ├── worker-service  → Sidekiq          — DATABASE_URL, REDIS_URL
  └── fe-service      → Next.js          — NEXT_PUBLIC_API_URL

Local Docker
  ├── backend   (port 3969)
  ├── sidekiq
  ├── frontend  (port 3001)  ← Next.js dev server
  ├── db        (port 5432)
  └── redis     (port 6379)
```

**Previous plan:** [07 — Docker + Cucumber](2026-04-23-06-docker-cucumber-deployment.md)

---

## Task 1: Bootstrap Next.js app

**Files:**
- Delete: `frontend/` (current Vite React app)
- Create: `frontend/` (new Next.js app)

- [ ] **Step 1: Scaffold Next.js inside `frontend/`**

```bash
cd ..  # repo root
rm -rf frontend
npx create-next-app@latest frontend \
  --typescript=false \
  --tailwind=false \
  --eslint=false \
  --app=false \
  --src-dir=false \
  --import-alias="@/*"
```

Use Pages Router (`--app=false`) to keep parity with current component structure.

- [ ] **Step 2: Install runtime dependencies**

```bash
cd frontend
npm install axios @rails/actioncable
```

- [ ] **Step 3: Configure `next.config.js`**

`frontend/next.config.js`:
```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // In development, proxy API and WebSocket to the Rails backend.
  async rewrites() {
    const beUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3969'
    return [
      { source: '/api/:path*', destination: `${beUrl}/api/:path*` },
      { source: '/cable',      destination: `${beUrl}/cable` },
    ]
  },
}

module.exports = nextConfig
```

- [ ] **Step 4: Create `frontend/.env.local` (gitignored)**

```
NEXT_PUBLIC_API_URL=http://localhost:3969
```

Only **one** env var needed. The WebSocket URL is derived automatically:
`http://…` → `ws://…` and `https://…` → `wss://…`

Add to `frontend/.gitignore` (already there from Next.js scaffold): `.env.local`

- [ ] **Step 5: Verify dev server starts**

```bash
cd frontend && npm run dev
```

Expected: Next.js dev server on http://localhost:3001

---

## Task 2: Migrate React components to Next.js

**Files:**
- Create: `frontend/pages/index.js`          ← main page (was App.jsx)
- Create: `frontend/pages/_app.js`            ← global layout
- Create: `frontend/components/Navbar.jsx`
- Create: `frontend/components/VideoList.jsx`
- Create: `frontend/components/VideoCard.jsx`
- Create: `frontend/components/ShareModal.jsx`
- Create: `frontend/components/NotificationToast.jsx`
- Create: `frontend/hooks/useAuth.js`
- Create: `frontend/hooks/useActionCable.js`
- Create: `frontend/api/client.js`

- [ ] **Step 1: API client**

`frontend/api/client.js`:
```js
import axios from 'axios'

const client = axios.create({
  baseURL: '/api/v1',  // rewrites proxy to NEXT_PUBLIC_API_URL/api/v1
})

client.interceptors.request.use(config => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('token')
    if (token) config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export default client
```

- [ ] **Step 2: Copy hooks (useAuth, useActionCable)**

Copy `useAuth.js` and `useActionCable.js` from the old `frontend/src/hooks/` verbatim.
Update `useActionCable.js` to derive the WebSocket URL from `NEXT_PUBLIC_API_URL`:

```js
// Derive ws(s):// from http(s):// — no separate WS env var needed.
const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3969'
const wsUrl  = apiUrl.replace(/^http/, 'ws')
consumerRef.current = createConsumer(`${wsUrl}/cable?token=${token}`)
```

- [ ] **Step 3: Copy components**

Copy these components verbatim from old `frontend/src/components/`:
- `Navbar.jsx`
- `VideoCard.jsx`
- `VideoList.jsx`
- `ShareModal.jsx`
- `NotificationToast.jsx`

No changes needed — they are plain React components with no Vite-specific code.

- [ ] **Step 4: Create `pages/_app.js`**

```js
import '../styles/globals.css'

export default function App({ Component, pageProps }) {
  return <Component {...pageProps} />
}
```

- [ ] **Step 5: Create `pages/index.js`** (port of `App.jsx`)

```js
import { useState, useEffect, useCallback } from 'react'
import Head from 'next/head'
import Navbar from '../components/Navbar'
import VideoList from '../components/VideoList'
import ShareModal from '../components/ShareModal'
import NotificationToast from '../components/NotificationToast'
import { useAuth } from '../hooks/useAuth'
import { useActionCable } from '../hooks/useActionCable'
import client from '../api/client'

export default function Home() {
  const { user, login, register, logout } = useAuth()
  const [videos, setVideos]               = useState([])
  const [showShareModal, setShowShareModal] = useState(false)
  const [notification, setNotification]   = useState(null)

  useEffect(() => {
    client.get('/videos').then(r => setVideos(r.data)).catch(() => {})
  }, [])

  const onNotification = useCallback(data => {
    setNotification(data)
  }, [])
  useActionCable(user, onNotification)

  const handleLogin = async (email, password) => {
    try { await login(email, password) }
    catch { await register(email, password) }
  }

  return (
    <>
      <Head><title>Funny Movies</title></Head>
      <Navbar
        user={user}
        onLogin={handleLogin}
        onLogout={logout}
        onShareClick={() => setShowShareModal(true)}
      />
      <main style={{ padding: '24px', maxWidth: '900px', margin: '0 auto' }}>
        <VideoList videos={videos} />
      </main>
      {showShareModal && (
        <ShareModal
          onClose={() => setShowShareModal(false)}
          onSuccess={video => { setVideos(prev => [video, ...prev]); setShowShareModal(false) }}
        />
      )}
      {notification && (
        <NotificationToast
          notification={notification}
          onDismiss={() => setNotification(null)}
        />
      )}
    </>
  )
}
```

- [ ] **Step 6: Create `styles/globals.css`**

```css
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: sans-serif; background: #f9f9f9; color: #222; }
```

- [ ] **Step 7: Smoke test in browser**

```bash
cd frontend && npm run dev
```

Open http://localhost:3001. Expected: app loads, login form visible, no console errors.

---

## Task 3: Update Docker Compose for Next.js

**Files:**
- Modify: `frontend/Dockerfile`
- Modify: `docker-compose.yml`

- [ ] **Step 1: Update `frontend/Dockerfile`**

```dockerfile
FROM node:20-slim AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install

FROM node:20-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public
EXPOSE 3001
CMD ["npm", "start"]
```

For development, override `CMD` in docker-compose.

- [ ] **Step 2: Update `docker-compose.yml` frontend service**

```yaml
  frontend:
    build: ./frontend
    command: npm run dev
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next
    ports:
      - '3001:3001'
    environment:
      NEXT_PUBLIC_API_URL: http://backend:3969
    depends_on:
      - backend
```

Also update `backend` service: remove `FRONTEND_URL: http://localhost:5173` → `FRONTEND_URL: http://localhost:3001`

- [ ] **Step 3: Rebuild and test**

```bash
docker compose down
docker compose up --build
```

Expected: all 5 services start, http://localhost:3001 shows the app.

- [ ] **Step 4: Commit**

```bash
git add . && git commit -m "feat: migrate frontend from Vite React to Next.js"
```

---

## Task 4: Railway deployment config

**Files:**
- Create: `railway.toml` (BE service config)
- Create: `frontend/railway.toml` (FE service config)

- [ ] **Step 1: Create root `railway.toml` (BE + Worker)**

```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "bundle exec puma -C config/puma.rb"
healthcheckPath = "/api/v1/videos"
restartPolicyType = "on_failure"
```

- [ ] **Step 2: Create `frontend/railway.toml`**

```toml
[build]
builder = "nixpacks"

[deploy]
startCommand = "npm start"
healthcheckPath = "/"
restartPolicyType = "on_failure"
```

- [ ] **Step 3: Add Procfile entry for Railway worker**

The existing `Procfile` already has:
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
```

On Railway, deploy BE as `web` process and Worker as a separate service using:
`bundle exec sidekiq`

- [ ] **Step 4: Verify production build locally**

```bash
cd frontend && npm run build && npm start
```

Expected: Next.js production server on port 3001.

- [ ] **Step 5: Commit**

```bash
git add . && git commit -m "feat: add Railway deployment config for BE and Next.js FE"
```

---

## Task 5: Update Cucumber tests for Next.js

Next.js uses server-side rendering — the page loads with HTML, then React hydrates.
Steps remain mostly the same; only ActionCable URL changes.

**Files:**
- Modify: `features/support/env.rb` (no change needed — already uses `FE_URL`)
- Verify: all 6 scenarios still pass

- [ ] **Step 1: Run Cucumber against Next.js FE**

```bash
RAILS_ENV=test FE_URL=http://localhost:3001 bundle exec cucumber
```

Expected: 6/6 scenarios pass. If any fail, screenshot is in `tmp/screenshots/`.

- [ ] **Step 2: Fix any failures**

Common issues:
- Next.js SSR: initial HTML may differ from React SPA (check selectors)
- ActionCable URL: derived from `NEXT_PUBLIC_API_URL` by replacing `http` → `ws`

- [ ] **Step 3: Commit**

```bash
git add . && git commit -m "feat: verify and fix Cucumber tests against Next.js FE"
```

---

## ENV vars summary

### BE / Worker (Railway)

| Var | Required | Notes |
|---|---|---|
| `DATABASE_URL` | ✅ | Auto-set by Railway PostgreSQL |
| `REDIS_URL` | ✅ | Auto-set by Railway Redis |
| `JWT_SECRET` | ✅ | Any random string |
| `RAILS_MASTER_KEY` | ✅ | Contents of `config/master.key` |
| `FRONTEND_URL` | ✅ | Next.js Railway URL (for CORS) |
| `RAILS_ENV` | ✅ | `production` |

### FE (Railway — Next.js)

| Var | Required | Notes |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | ✅ | BE Railway URL, e.g. `https://myapp-be.up.railway.app` (WS URL derived automatically: `https://…` → `wss://…`) |
| `PORT` | auto | Railway sets this (Next.js respects it) |
