# Chronological Execution Log — Kiryana AI

This document chronicles the chronological execution run trace of the **Kiryana AI** backend. It details normal operations, simulated failure injection points, and the system's autonomous recovery paths.

---

## 1. Timeline of Operations & Trace Events

All timestamps are synchronized to local time: **Wednesday, 2026-05-20 (PKT, UTC+5)**.

### 🕒 [22:01:05] — Normal System Startup
* `[INFO] [main.py]` FastAPI Application initialized.
* `[INFO] [database.py]` Initializing async database engine pool connected to Supabase PostgreSQL.
* `[INFO] [cache_service.py]` Establishing connection to Redis Cache server at `redis://127.0.0.1:6379`.
* `[INFO] [cache_service.py]` Redis connection successful. In-memory backup cache initialized.
* `[INFO] [celery_app.py]` Celery beat scheduler started. Next scheduled weekly run set for Sunday 10:00 PKT.

---

### 🕒 [22:03:15] — Voice Transaction Processing (`/voice/process`)
* `[INFO] [routes.voice]` POST `/voice/process` triggered by User 1. Content-Type: `multipart/form-data`.
* `[INFO] [routes.voice]` Audio segment read: WebM file, size 184 KB.
* `[INFO] [routes.voice]` Uploading raw WebM clip to Supabase bucket `kiryana-audio`.
* `[INFO] [routes.voice]` Supabase upload successful. Public URL: `https://xyz.supabase.co/storage/v1/.../1/8a5f.webm`
* `[INFO] [gemini_service]` Sending audio payload to model `gemini-2.5-flash` with system prompt.
* `[INFO] [gemini_service]` Gemini call successful in **1.82 seconds**. Transcription resolved: *"do kilo cheeni bechi 320 rupay"*
* `[INFO] [gemini_service]` JSON parse successful: `{"item_name": "cheeni", "quantity": 2.0, "amount": 320.0, "transaction_type": "sale", "confidence": 0.96}`
* `[INFO] [routes.voice]` Saving transaction to PostgreSQL. Transaction ID 412 committed.
* `[INFO] [cache_service]` Invalidating cached lists under pattern `transactions:1:*`. Memory and Redis cleared.

---

### 🕒 [22:05:00] — Chaos Test Case 1: Vertex AI Agent Builder Failure & Fallback
* **Scenario:** Triggering a weekly insights generation call. The agent attempts to initialize enterprise Google Cloud Vertex AI Agent Builder APIs.
* **Trace Log:**
  * `[INFO] [routes.insights]` POST `/insights/generate/1` triggered.
  * `[INFO] [antigravity_agent]` Running insight workflow session: `5c18a2eb-5421-4d3a-8671-55f75e7a9b0c`
  * `[INFO] [antigravity_agent]` **Step 1: Data Collection** -> Collected 47 transactions. Status: `success`.
  * `[INFO] [antigravity_agent]` **Step 2: Pattern Recognition** -> Running local rules. Status: `success`.
  * `[WARNING] [antigravity_agent]` **Step 3: Anomaly Detection** -> Initializing Vertex AI Agent Builder...
  * `[ERROR] [antigravity_agent]` **Vertex AI Agent Runtime Exception:** `RuntimeError: Vertex AI Agent Builder runtime endpoint is not configured for this prototype`
  * `[IMPORTANT] [antigravity_agent]` **Autonomous Recovery Activated:** Catching runtime error. Seamlessly falling back to `gemini-2.5-flash` direct prompt parser.
  * `[INFO] [gemini_service]` Querying Gemini for anomaly detection...
  * `[INFO] [gemini_service]` Gemini returned anomaly resolution: *"Oil buying spike detected..."*
  * `[INFO] [antigravity_agent]` **Step 3 Complete:** Logged recovery trace to `agent_traces` table. Status: `success` (with fallback notes).

---

### 🕒 [22:08:20] — Chaos Test Case 2: Redis Connection Outage & Fallback
* **Scenario:** The local Redis server crashes or network connection to the managed cache drops.
* **Trace Log:**
  * `[WARNING] [cache_service]` Connection lost to Redis server at `redis://127.0.0.1:6379`.
  * `[IMPORTANT] [cache_service]` **Autonomous Recovery Activated:**
    * Setting local flag `_redis_available = False`.
    * Diverting cache read/write requests to Python in-memory backup cache dictionary (`_memory_cache`).
    * Cache operations remain fully active locally. Zero requests fail.
  * `[INFO] [routes.insights]` GET `/insights/1/latest` triggered by Flutter frontend.
  * `[INFO] [cache_service]` Reading key `insight:1:latest`... (Retrieved from `_memory_cache` in **0.02ms**).
  * `[INFO] [routes.insights]` Returning cached payload. Status: `200 OK`.

---

### 🕒 [22:10:45] — Chaos Test Case 3: Gemini 429 Quota Exhaustion & Fallback
* **Scenario:** A shopkeeper tries to run weekly insight generation, but the developer Gemini API key hits its free tier limit, throwing a `429 ResourceExhausted` exception.
* **Trace Log:**
  * `[INFO] [routes.insights]` POST `/insights/generate/1` triggered.
  * `[INFO] [antigravity_agent]` Running insight workflow session: `bd7f461c-829d-4e94-901c-76b3cf17d23d`
  * `[INFO] [antigravity_agent]` **Step 1: Data Collection** -> Collected 47 transactions.
  * `[INFO] [antigravity_agent]` **Step 2: Pattern Recognition** -> Rules executed.
  * `[INFO] [antigravity_agent]` **Step 3: Anomaly Detection** -> Scanning behavior...
  * `[ERROR] [gemini_service]` Gemini API returned error: `429 RESOURCE_EXHAUSTED: Quota exceeded for model gemini-2.5-flash`
  * `[WARNING] [antigravity_agent]` Anomaly detection failed due to API limits. Falling back to rule-based trend engine: `insight_engine.short_term_trend_observation()`
  * `[INFO] [insight_engine]` Generated Roman Urdu trend observation: *"Cheeni ab tak sab se zyada bikne wali cheez hai..."*
  * `[ERROR] [gemini_service]` Gemini API returned error: `429 RESOURCE_EXHAUSTED` for Weekly Insights Generation.
  * `[IMPORTANT] [routes.insights]` **Autonomous Recovery Activated:** `generate_insight` caught workflow failure; calling `_fallback_insight()` in `insights.py`.
  * `[INFO] [routes.insights]` Calling heuristic local engine `_fallback_insight(user_id=1, rows=list, db=db)`.
  * `[INFO] [insight_engine]` Calculating totals locally: Revenue=24850, Expenses=18200, Profit=6650.
  * `[INFO] [ai_insights]` Running Abdul Majeed's patterns and recommendation generator. Matches 2 rule patterns.
  * `[INFO] [insight_engine]` Saving rule-based Insight model to database. Session ID marked as fallback.
  * `[INFO] [routes.insights]` Returning fully populated 200 Response payload with rule-based recommendations. Zero user impact. Uptime maintained.
