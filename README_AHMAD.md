# ai-insights — Ahmad ke liye Integration Guide

Yeh module Abdul Majeed ne banaya hai. Neeche exactly woh sab kuch hai jo tumhe karna hai.

---

## 1. DB Schema

Apna `transactions` table exactly is tarah banao — column names same hone chahiye:

```sql
CREATE TABLE transactions (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL,
    date          TEXT NOT NULL,          -- format: 'YYYY-MM-DD'
    item_name     TEXT NOT NULL,
    quantity      REAL NOT NULL,
    unit_price    REAL NOT NULL,
    total_amount  REAL NOT NULL,          -- quantity * unit_price
    type          TEXT NOT NULL CHECK(type IN ('sale', 'expense')),
    vendor_id     INTEGER                 -- NULL for sales is fine
);

CREATE TABLE users (
    id    INTEGER PRIMARY KEY,
    name  TEXT,
    phone TEXT                            -- WhatsApp number, e.g. '+923001234567'
);

CREATE TABLE vendors (
    id   INTEGER PRIMARY KEY,
    name TEXT
);
```

> **Important:** Esha ke parsed JSON se jo data aata hai usse `transactions` mein insert karo.
> Har voice entry mein do rows ho sakti hain — ek `expense` (purchase cost) aur ek `sale` (selling price).
> Agar sirf sale log ho rahi hai to sirf `sale` type insert karo — module dono handle karta hai.

---

## 2. .env File

Apne project root mein `.env` file mein yeh add karo:

```
GEMINI_API_KEY=your_api_key_here
```

Gemini API key Google AI Studio se milti hai: https://aistudio.google.com/app/apikey

Module khud `.env` nahi load karta — tumhare Flask/FastAPI app ne pehle se `python-dotenv` load karna hoga ya env variable set karna hoga.

---

## 3. Dependencies Install Karo

```bash
pip install -r requirements_insights.txt
```

---

## 4. Module Ko Call Karo

```python
from ai_insights import run_insight_pipeline

result = run_insight_pipeline(user_id=1, db_path="kiryana.db")
```

`result` ek dictionary hai jisme yeh hoga:

```python
{
    "week_totals": {
        "revenue":  11357.5,   # is hafte ki total kamai
        "expenses": 9246.0,    # is hafte ka total kharcha
        "profit":   2111.5,    # munafa (negative = nuqsan)
    },
    "patterns": [
        {
            "type":     "margin_shrink",       # pattern ki type
            "item":     "Sugar",               # item name (ya None)
            "weekday":  None,                  # weekday name (ya None)
            "message":  "Sugar ka margin...",  # Roman Urdu description
            "severity": "high" | "medium" | "low"
        },
        # ... more patterns
    ],
    "recommendations": [
        {
            "pattern_type":      "margin_shrink",
            "item":              "Sugar",
            "weekday":           None,
            "action_roman_urdu": "Is item ki selling price thodi barha dein...",
            "source":            "rule" | "gemini"
        },
        # ... one recommendation per pattern
    ],
    "report_text": "📊 *Hafte Ki Report*\n\n💰 Kamai: Rs. 11,358\n...",
    "top_insight": { ... }  # highest-severity pattern, ya None
}
```

---

## 5. Endpoints Jo Tumhe Banana Hai

### GET /api/insights/\<user_id\>
Frontend ke liye — patterns aur recommendations return karo.

```python
@app.get("/api/insights/<int:user_id>")
def get_insights(user_id):
    result = run_insight_pipeline(user_id=user_id, db_path=DB_PATH)
    return jsonify({
        "week_totals":     result["week_totals"],
        "patterns":        result["patterns"],
        "recommendations": result["recommendations"],
        "top_insight":     result["top_insight"],
    })
```

### POST /api/report/\<user_id\>
WhatsApp pe weekly report bhejne ke liye — `result["report_text"]` Twilio ko pass karo.

```python
@app.post("/api/report/<int:user_id>")
def send_report(user_id):
    result = run_insight_pipeline(user_id=user_id, db_path=DB_PATH)
    # Twilio call yahan karo:
    client.messages.create(
        from_="whatsapp:+14155238886",
        to=f"whatsapp:{user_phone}",
        body=result["report_text"]
    )
    return jsonify({"status": "sent"})
```

---

## 6. Test Karo (Meri DB Se)

```bash
python seed_test_db.py
```

Yeh `test.db` banata hai aur poora pipeline run karta hai — output terminal mein print hoga.
Agar yeh kaam kare to tumhara integration bhi kaam karega.

---

## 7. Folder Structure

```
kiryana/
├── ai_insights/          ← Majeed ka module (branch: ai-insights)
│   ├── __init__.py
│   ├── agent.py
│   ├── db.py
│   ├── patterns.py
│   ├── recommender.py
│   └── report.py
├── seed_test_db.py       ← test script
├── requirements_insights.txt
└── README_AHMAD.md       ← yeh file
```

---

## Quick Checklist

- [ ] `transactions` table ka schema upar wale se match karta hai
- [ ] `.env` mein `GEMINI_API_KEY` add kiya
- [ ] `pip install -r requirements_insights.txt` run kiya
- [ ] `python seed_test_db.py` se test kiya — output aaya
- [ ] `/api/insights/<user_id>` endpoint bana diya
- [ ] `/api/report/<user_id>` endpoint bana diya (Twilio ke saath)

Koi masla ho to Majeed ko batao.
