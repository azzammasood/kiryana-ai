# Kiryana AI — Deploy (free until 25 May demo)

You need **two parts** live:

| Part | Free host | URL example |
|------|-----------|-------------|
| Backend (FastAPI) | [Render](https://render.com) | `https://kiryana-ai-api.onrender.com` |
| Frontend (Flutter web) | [Netlify Drop](https://app.netlify.com/drop) or [Cloudflare Pages](https://pages.cloudflare.com) | `https://your-app.netlify.app` |

APK is built on your PC and installed on Android (no store needed for demo).

---

## Part 1 — Deploy backend on Render (free)

1. Push this repo to **GitHub** (private is fine).
2. Go to [render.com](https://render.com) → **New** → **Blueprint** → connect repo.
3. Render reads `render.yaml` and creates **kiryana-ai-api**.
4. In Render → **Environment**, add the same variables as `backend/.env`:
   - `DATABASE_URL` (Supabase pooler URL)
   - `GEMINI_API_KEY`
   - `GOOGLE_CLOUD_PROJECT`
   - `GOOGLE_APPLICATION_CREDENTIALS` — for Render, paste JSON into env or use a path; easiest: set `TEST_MODE=true` for demo if Gemini quota is an issue
   - `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`
   - Twilio vars (optional)
5. After deploy, open: `https://YOUR-SERVICE.onrender.com/health` → should show `{"status":"ok",...}`.

**Note:** Free Render sleeps after ~15 min idle. First request after sleep takes ~30–60s (cold start). Fine for hackathon until **25 May**.

**Migrations (once):** Render **Shell** or local:

```powershell
cd backend
$env:DATABASE_URL="your_supabase_url"
.\.venv\Scripts\python.exe -m alembic upgrade head
```

---

## Part 2 — Mobile web app (phone browser)

### Build locally

Replace `API_URL` with your Render URL (no trailing slash):

```powershell
cd C:\Users\LENOVO\Documents\personal\Projects\kiryana-ai-new
.\scripts\build_web.ps1 -ApiUrl "https://kiryana-ai-api.onrender.com"
```

Output folder: `kiryana-ai-frontend\build\web`

### Option A — Netlify Drop (fastest, no Git)

1. Open [https://app.netlify.com/drop](https://app.netlify.com/drop)
2. Drag the folder `kiryana-ai-frontend\build\web` onto the page.
3. Netlify gives a URL like `https://random-name.netlify.app`.
4. Open that URL on your phone — it runs in **mobile layout** (viewport is configured).

### Option B — Cloudflare Pages

1. [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → **Create** → **Pages** → **Upload assets**.
2. Upload contents of `build\web` (zip the folder first if needed).
3. Use the `*.pages.dev` URL on mobile.

### Option C — Netlify connected to GitHub

1. Netlify → **Add site** → **Import from Git**.
2. Base directory: `kiryana-ai-frontend`
3. Build command: `flutter build web --release --dart-define=API_BASE_URL=https://YOUR-API.onrender.com`
4. Publish directory: `build/web`
5. Add env var `API_BASE_URL` in Netlify build settings.

---

## Part 3 — Android APK

### Prerequisites

- Android SDK (via Android Studio once, or `flutter doctor` green for Android)
- Same `API_URL` as web

### Build

```powershell
cd C:\Users\LENOVO\Documents\personal\Projects\kiryana-ai-new
.\scripts\build_apk.ps1 -ApiUrl "https://kiryana-ai-api.onrender.com"
```

APK path:

`kiryana-ai-frontend\build\app\outputs\flutter-apk\app-release.apk`

### Install on phone

1. Copy `app-release.apk` to the phone (USB / Drive / WhatsApp).
2. Enable **Install unknown apps** for Files/WhatsApp.
3. Tap APK → Install.

**Mic permission:** Allow microphone when the app asks (Speak / Get help from AI).

---

## Checklist before demo (25 May)

- [ ] `https://YOUR-API.onrender.com/health` returns OK
- [ ] Web URL opens on phone; login works
- [ ] APK installed; points to same API (rebuild if API URL changes)
- [ ] `GEMINI_API_KEY` valid or `TEST_MODE=true` on Render
- [ ] Do not commit `.env` or `gcp-service-account.json` to GitHub

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Web blank / 404 on refresh | Redeploy with `netlify.toml` redirects (included) |
| API connection failed | APK/web built with wrong `API_BASE_URL`; rebuild with correct Render URL |
| Render very slow first load | Free tier cold start; wait 60s or upgrade temporarily |
| APK build fails | Run `flutter doctor`; install Android SDK & accept licenses |
