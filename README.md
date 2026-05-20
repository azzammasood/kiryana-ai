# KiryanaAI

KiryanaAI is a voice-first expense manager for Pakistani kiryana store owners and street vendors. A shopkeeper speaks in Urdu, Roman Urdu, or English, and the app transcribes the audio, extracts a sale or expense, stores it, generates weekly business insights, records an agent trace, and can send the summary through WhatsApp.

Built for Google AISeekho 2026 Hackathon, Challenge 1: Autonomous Content-to-Action Agent.

## Architecture

```text
Expo mobile app
  -> FastAPI backend
      -> Supabase PostgreSQL through async SQLAlchemy
      -> Supabase Storage for voice clips
      -> Gemini 1.5 Flash for transcription, parsing, insights
      -> Vertex AI / Antigravity workflow layer for traceable orchestration
      -> Redis cache for summaries, insights, transaction lists
      -> Celery beat/worker for weekly WhatsApp reports
      -> Twilio WhatsApp API
```

## Team Work Integrated

- Esha Shabbir: `ai_voice/` Urdu multimodal parser prototype.
- Abdul Majeed: `ai_insights/` pattern detection and recommendation prototype.
- Muhammad Usman: `kiryana-ai-frontend/` Flutter mobile prototype used as UI/flow reference.
- Muhammad Jamil: `KiryanaAi screens.zip` UI/UX screenshots archived for design evidence.
- Ahmad: production integration, backend API, Expo mobile app, Antigravity evidence package.

## Prerequisites

- Node.js and npm
- Expo CLI through `npx expo`
- Python 3.10-3.12 for the pinned backend dependencies
- PostgreSQL or Supabase PostgreSQL
- Redis
- Gemini API key
- Google Cloud project with Vertex AI enabled
- Supabase project and storage bucket
- Twilio WhatsApp sandbox or production sender

## Backend Setup

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
alembic -c alembic.ini upgrade head
uvicorn main:app --reload
```

Seed demo data while the backend is running:

```bash
python seed.py
```

Celery:

```bash
celery -A celery_app worker --loglevel=info
celery -A celery_app beat --loglevel=info
```

## Frontend Setup

```bash
npm install
npm start
```

For a physical phone, edit [src/config.js](C:/Users/LENOVO/Documents/personal/Projects/kiryana-ai-new/src/config.js) and replace `localhost` with your machine LAN IP.

## Environment Variables

Backend variables live in `backend/.env`:

- `DATABASE_URL`
- `REDIS_URL`
- `GEMINI_API_KEY`
- `GOOGLE_CLOUD_PROJECT`
- `GOOGLE_CLOUD_LOCATION`
- `GOOGLE_APPLICATION_CREDENTIALS`
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_WHATSAPP_NUMBER`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY`
- `SUPABASE_AUDIO_BUCKET`
- `TEST_MODE` optional; set `true` only for local end-to-end tests without paid external API calls.

## Theme System

The Expo app uses one theme source: [src/theme/theme.js](C:/Users/LENOVO/Documents/personal/Projects/kiryana-ai-new/src/theme/theme.js). Colors, spacing, radii, icon sizes, elevation, and animation timings are centralized there.

## API Endpoints

- `GET /health` returns app health.
- `POST /users/` body `{ phone_number, name }`, idempotently creates or returns a user.
- `GET /users/{user_id}` returns user profile.
- `PUT /users/{user_id}` updates `name` or `language`.
- `POST /voice/transcribe` multipart `{ audio_file, user_id }`, uploads audio and returns transcription.
- `POST /voice/parse` body `{ text, user_id }`, returns parsed transaction JSON.
- `POST /transactions/` saves a transaction.
- `GET /transactions/{user_id}?filter=today|week|month` lists transactions.
- `GET /transactions/{user_id}/summary` returns today totals.
- `GET /transactions/{user_id}/recent` returns last 3 transactions.
- `DELETE /transactions/{transaction_id}` deletes one transaction.
- `POST /insights/generate/{user_id}` runs the 7-step agent workflow.
- `GET /insights/{user_id}/latest` returns latest insight.
- `GET /insights/{user_id}/trace` returns latest session trace.
- `POST /notifications/whatsapp/{user_id}` attempts WhatsApp delivery.
- `GET /notifications/settings/{user_id}` returns notification settings.
- `PUT /notifications/settings/{user_id}` updates notification settings.

## Gemini Usage

- Audio transcription preserves Urdu, Roman Urdu, and English exactly as spoken.
- Transaction parsing returns strict JSON with item, quantity, unit, PKR amount, type, and confidence.
- Weekly insights generate recommendations, key insight, and WhatsApp-ready Urdu summary.
- Anomaly detection scans recent transaction behavior and feeds action planning.

## Antigravity / Vertex AI Role

KiryanaAI records an Antigravity-style agent trace for every weekly insight run:

1. Data Collection
2. Pattern Recognition
3. Anomaly Detection
4. Insight Generation
5. Action Planning
6. Report Compilation
7. Execution Complete

The service initializes Vertex AI with the configured Google Cloud project. If a deployed Agent Builder runtime is not configured, it falls back to Gemini and records the fallback in `agent_traces`, so judges can see observation, reasoning, decision, action, recovery, and outcome.

## Challenge 1 Mapping

- Content-to-action: voice input becomes saved transaction and weekly report.
- Agentic workflow: backend records seven explicit orchestration steps.
- Tool/API use: Gemini, Supabase Storage/PostgreSQL, Redis, Celery, Twilio, Vertex AI initialization.
- Visible outcome: mobile screens show saved transactions, recommendations, WhatsApp send, and trace timeline.
- Robustness: Twilio failures return `sent: false`; Redis failures degrade gracefully; Vertex unavailable falls back to Gemini.
- Cost/scaling: Gemini Flash keeps per-call cost low; Redis caches heavy reads; Celery batches weekly reports.

## Cost and Scalability Notes

Typical user flow uses one audio transcription call, one parser call, and one transaction insert. Weekly insight generation uses one anomaly call and one insight call. Redis caches dashboard reads for 3-10 minutes. For 10x/100x use, scale FastAPI workers horizontally, use managed Redis, and move Celery to a dedicated worker pool.
