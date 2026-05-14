# KiryanaAI

**Voice-first expense manager for small traders** (kiryana stores, street vendors). This repo includes the **`ai-voice`** module: upload Urdu / English / Roman-Urdu / mixed audio and receive a validated JSON payload ready for a ledger API.

---

## feat(ai-voice): Multimodal Urdu voice parser

- **Gemini 2.5 Flash** — direct **audio → structured JSON** in one multimodal call (`google-genai` SDK, `types.Part.from_bytes`).
- **NLP extraction** — item, quantity, unit, price, transaction type (`sale` / `expense` / `purchase`), optional Urdu item name, notes, per-line and overall confidence.
- **Edge cases** — incomplete or noisy utterances, mixed dialects and code-switching, **desi fractions** (e.g. sawa, dedh, paav), **number words** (e.g. do hazar, teen sau), missing or unknown units; low-confidence paths populate bilingual prompts.
- **Resilience** — **exponential backoff retries** on API failures (covers transient errors such as **503** / rate limits / network blips); failures return a **safe JSON** contract with `processing_status: "failed"` and **Urdu + English** `user_friendly_message` instead of crashing callers.
- **Contract** — **Pydantic v2** schema, **`response_mime_type: application/json`**, and **`VoiceTransactionResult.to_api_dict()`** for clean backend integration.

---

## Requirements

- Python **3.10+**
- [Gemini API key](https://aistudio.google.com/apikey) (`GEMINI_API_KEY`)

---

## Quick start

```bash
python -m venv venv
# Windows: venv\Scripts\activate
# Unix:    source venv/bin/activate

pip install -r requirements.txt
```

Copy environment template and add your key:

```bash
cp .env.example .env.local   # or .env — both are gitignored
```

`main.py` loads `.env` first, then **`.env.local`** (overrides).

### CLI (test a clip)

```bash
python main.py path/to/recording.wav --pretty
python main.py path/to/clip.ogg --context "Vegetable stall" --items "atta,chawal,doodh"
```

Supported extensions include `.wav`, `.mp3`, `.ogg`, `.mp4` (audio), `.m4a`, `.flac`, `.aac`, `.webm` (see `ai_voice/engine.py`).

### Library usage

```python
from ai_voice import VoiceEngine

engine = VoiceEngine()  # uses GEMINI_API_KEY
result = engine.process_audio("clips/sale.ogg", context_hint="Kiryana in Karachi")
payload = result.to_api_dict()
```

---

## Tests

```bash
python -m pytest tests/ -q
```

Integration tests **mock** the Gemini client; no API key required for CI.

---

## Project layout

| Path | Purpose |
|------|---------|
| `ai_voice/engine.py` | Gemini client, retries, audio parts, JSON parse & validate |
| `ai_voice/prompts.py` | System prompt (dialects, fractions, units, confidence rules) |
| `ai_voice/schema.py` | Pydantic models and `to_api_dict()` |
| `main.py` | CLI entrypoint |
| `tests/test_voice.py` | Schema, prompts, engine (mocked) |
| `.env.example` | Template for `GEMINI_API_KEY` (safe to commit) |

---

## JSON output (high level)

Top-level fields include: `transactions[]`, `raw_transcript`, `normalized_transcript`, `detected_language`, `confidence_score`, `processing_status`, `user_friendly_message`, `recorded_at_hint`, `processed_at`, rollup totals (`total_sales_pkr`, etc.). Each transaction includes `item_name`, `quantity`, `unit`, `price`, `transaction_type`, and more — see **`ai_voice/schema.py`** for the full contract.

---

## Security & Git

- **Never commit** `.env`, `.env.local`, or real API keys. Use `.env.example` only as a template.
- Voice clips belong under **`clips/`** or similar; see **`.gitignore`** for ignored paths and local audio patterns.

---

## License / team

Built for **#AISeekho2026 / Antigravity Hackathon** — KiryanaAI product track. Adjust `pyproject.toml` / license as your team decides.
