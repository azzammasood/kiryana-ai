# API & Tool Transaction Logs — Kiryana AI

This document catalogs the exact inputs, outputs, schemas, and step mappings for every tool and API call managed by the **Kiryana AI** agent.

---

## 1. Tool Call Trace Table

| Tool / API | Step # | Purpose | Request Payload / Input | Response Payload / Output |
| :--- | :--- | :--- | :--- | :--- |
| **Supabase Storage** | Pre-Step | Voice Upload | **File:** Raw binary voice clip (`audio/webm`), **Path:** `1/8a5f3e9b-4c2d-41a2.webm` | `{"publicUrl": "https://xyz.supabase.co/storage/v1/object/public/kiryana-audio/1/8a5f3e9b-4c2d-41a2.webm"}` |
| **Gemini 2.5 Flash** | Pre-Step | Voice Transcribe & Parse | **Input:** Audio bytes + **System Prompt:** *"Transcribe audio exactly... Return JSON with item_name, quantity, price, transaction_type..."* | `{"raw_transcript": "do kilo cheeni bechi 320 rupay", "detected_language": "roman_urdu", "transactions": [{"item_name": "cheeni", "quantity": 2.0, "unit": "kg", "price": 320.0, "transaction_type": "sale", "confidence": 0.96}]}` |
| **Supabase DB** | Pre-Step | Commit Transaction | **SQL:** `INSERT INTO transactions (user_id, item_name, quantity, unit, amount, transaction_type, raw_text, audio_url, date) VALUES (1, 'cheeni', 2.0, 'kg', 320.0, 'sale', 'do kilo cheeni bechi 320 rupay', 'https://...', '2026-05-20')` | `Row ID: 412 (Success)` |
| **Redis Cache** | Read | Cache Hit Check | **Key:** `insight:1:latest` | `None (Cache Miss)` |
| **Supabase DB** | Step 1 | Data Collection | **SQL:** `SELECT * FROM transactions WHERE user_id = 1 AND date >= '2026-05-18' AND date <= '2026-05-24' ORDER BY date ASC` | Array of 47 Transaction Row Objects |
| **Gemini 2.5 Flash** | Step 3 | Anomaly Detection | **Prompt:** *"The ledger has 47 entries... Return ONE practical tip in Roman Urdu... [JSON transaction list]"* | `"Cheeni aur atta ka expense Monday ko Rs. 15,000 barh gaya hai. Bulk purchasing weekend se pehle karein taake discounts milein."` |
| **Gemini 2.5 Flash** | Step 4 | Insight Generation | **Prompt:** *"Weekly data: Total Sales: Rs. 24850, Expenses: Rs. 18200... Return JSON with recommendations, key_insight, report_text..."* | `{"recommendations": ["Ghee ka stock check karein.", "Udhaar records note karein."], "key_insight": "Net profit is positive.", "report_text": "Assalam o Alaikum, is hafte bikri Rs. 24,850 rahi..."}` |
| **Supabase DB** | Step 5 | Feed Adaptation | **SQL:** `SELECT * FROM recommendation_feedback WHERE user_id = 1 ORDER BY created_at DESC LIMIT 80` | Array of 12 feedback records (Accepted = 8, Rejected = 4) |
| **Supabase DB** | Step 7 | Commit Results | **SQL:** `INSERT INTO insights (user_id, session_id, week_start, week_end, total_sales, total_expenses, profit, top_items, recommendations, key_insight, report_text) VALUES (...)` | `Row ID: 31 (Success)` |
| **Redis Cache** | Write | Populate Cache | **Key:** `insight:1:latest`, **TTL:** `600s`, **Value:** `Insight JSON payload` | `True` |
| **Twilio WhatsApp** | Notify | WhatsApp Dispatch | **Post Request:** `https://api.twilio.com/2010-04-01/.../Messages.json`, **Payload:** `To: whatsapp:+923001234567, Body: "Assalam o Alaikum..."` | `{"sid": "SMa85b6c...", "status": "queued", "date_created": "2026-05-20T22:15:00Z"}` |
| **Gemini 2.5 Flash** | Ask AI | Voice Q&A (Get help from AI) | **POST** `/voice/ask` — **Form:** `audio_file` (webm), `user_id=1`, optional `question_hint`; **Context:** latest insight + week transactions from DB | `{"user_id": 1, "transcription": "is hafte sab se zyada kya becha?", "answer": "Is hafte Atta aur Cheeni top items rahe..."}` |
| **Supabase DB** | Learning | Voice answer feedback | **POST** `/insights/feedback/voice` — `{"user_id": 1, "question": "...", "answer": "...", "rating": "up"}` | `{"saved": true, "feedback_id": 18}` |
| **Supabase DB** | Learning | Recommendation feedback | **POST** `/insights/feedback/recommendation` — `{"user_id": 1, "recommendation_text": "...", "accepted": true}` | `{"saved": true, "feedback_id": 19}` |
| **Supabase DB** | KPIs | Learning Statistics screen | **GET** `/insights/1/kpis` | `{"user_id": 1, "voice_feedback_total": 24, "voice_feedback_up": 20, "recommendation_feedback_total": 12, "recommendation_accepted": 8}` |

---

## 2. Key Payload Structures

### Gemini Voice Extraction Output (`/voice/process`)
```json
{
  "raw_transcript": "2 carton oil kharida factory se 4500 ka aur aik bori chawal becha 3500 ka",
  "detected_language": "roman_urdu",
  "confidence_score": 0.94,
  "processing_status": "success",
  "transactions": [
    {
      "item_name": "oil",
      "quantity": 2.0,
      "unit": "carton",
      "amount": 4500.0,
      "transaction_type": "expense",
      "confidence": 0.95,
      "raw_text": "2 carton oil kharida factory se 4500 ka aur aik bori chawal becha 3500 ka",
      "audio_url": "https://xyz.supabase.co/storage/v1/object/public/kiryana-audio/1/audio.webm",
      "transaction_date": "2026-05-20"
    },
    {
      "item_name": "chawal",
      "quantity": 1.0,
      "unit": "bori",
      "amount": 3500.0,
      "transaction_type": "sale",
      "confidence": 0.93,
      "raw_text": "2 carton oil kharida factory se 4500 ka aur aik bori chawal becha 3500 ka",
      "audio_url": "https://xyz.supabase.co/storage/v1/object/public/kiryana-audio/1/audio.webm",
      "transaction_date": "2026-05-20"
    }
  ],
  "engine": "ai-voice-prompts/gemini-2.5-flash"
}
```

### Gemini Weekly Insight Output (`/insights/generate/{user_id}`)
```json
{
  "recommendations": [
    "Atta ka stock Wednesday ko reorder karein taake weekend ki demand poori ho sake.",
    "Bikri barh rahi hai, sham 6 se 9 ke darmiyan counter par chota display lagayein.",
    "Daily expenses ko voice se lazmi log karein taake profit accuracy behtar ho."
  ],
  "key_insight": "Is hafte sales expenses se 36% zyada raheen, jis se aap ka profit Rs. 6,650 positive raha.",
  "report_text": "Assalam o Alaikum! Is hafte aap ki dukaan ki total bikri Rs. 24,850 aur total kharcha Rs. 18,200 raha, jis se aap ka net faida Rs. 6,650 bana. Top selling item Atta raha. Mazeed tips ke liye app check karein."
}
```
