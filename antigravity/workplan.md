# Project Workplan — Kiryana AI

## 1. Context & Background
Pakistani *kiryana* (neighborhood grocery) stores and street vendors operate in a fast-paced, cash-dominant environment. These shopkeepers (*dukandaars*) rarely have the time, tech literacy, or willingness to type long lists of sales and expenses into a standard mobile application. 

**Kiryana AI** was conceived to solve this friction by providing a voice-first, highly localized financial ledger. The vendor speaks naturally in a mix of Urdu, Roman Urdu, and English (e.g., *"Cheeni do kilo kharidi paanch sau rupay"*). The app handles voice parsing, extracts structured data, commits it to a relational ledger, detects business patterns, and acts by compiling weekly insight summaries delivered via WhatsApp.

---

## 2. Challenge 1 Scope: Autonomous Content-to-Action
Kiryana AI addresses Google AISeekho 2026 Challenge 1 by implementing an end-to-end, voice-driven autonomous workflow:

* **Multimodal Voice Input:** Transcribes raw voice files (transmissions containing Urdu script, Roman Urdu transliterations, and localized slang) using Gemini.
* **Content to Structured Action:** Parses unstructured speech into formal financial models (pk amount, product type, quantities, and sales/expenses categorization) and updates a Supabase PostgreSQL ledger.
* **Weekly Run Loop:** Triggers an autonomous 7-step analytical pipeline to analyze weekly transactions.
* **Feedback Loop:** Implements reinforcement learning by allowing shopkeepers to accept or reject recommendations, directly adapting the recommendations output for the following week.
* **Notification Actions:** Auto-compiles WhatsApp reports ready for dispatch via Twilio.

---

## 3. Key Technical Risks & Localized Mitigation

| Identified Risk | Impact | Localized Mitigation Strategy |
| :--- | :--- | :--- |
| **API Limit / Gemini Quota Exhaustion** | High | Built a robust **dual-layer fallback architecture** that catches resource errors and triggers in-memory heuristic code (`insight_engine.py`) to keep the app 100% functional. |
| **Noisy Market Environments** | Medium | Configured transcription prompts to expect background static, vendor shouting, and ambient noise. Prompting restricts Gemini to return strictly spoken shop ledger data. |
| **Connectivity & Cold Starts** | High | Since the backend is deployed on a free Render tier, we implemented **Redis Caching** with in-memory fallback to minimize API calls and keep dashboard loading snappy (< 1s). |
| **User Trust & Roman Urdu** | Medium | Avoided complex English terms and standard Urdu script (which is hard to read on-the-go). Output insights are formatted in clean, conversational Roman Urdu (*"Assalam o Alaikum, is hafte bikri Rs..."*). |

---

## 4. Success Criteria

We measure the success of the Kiryana AI engine against the following objective key results (OKRs):

1. **End-to-End Voice Processing Latency:** Transcription and parsing must complete in under **4.5 seconds** on active connections (excluding Render's 30s cold-starts).
2. **Transaction Extraction Accuracy:** Multimodal parser must accurately resolve `item_name`, `amount`, and `transaction_type` on at least **92%** of standard local phrases.
3. **Graceful Service Degradation:** 100% uptime even if Redis is down, Twilio is blocked, or Gemini API limits are hit, using rule-based calculations and local dictionaries.
4. **Agent Action Verifiability:** Every action, fallback step, and recommendation update must be written transparently to the `agent_traces` ledger, visible to users on the dashboard.
