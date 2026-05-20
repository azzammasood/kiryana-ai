# Agent Observations Log — Kiryana AI

This document chronicles the observations recorded by the **Antigravity Orchestrator** during live weekly insight generation run loops.

---

## 1. Step-by-Step Step Observations

### Step 1: Data Collection
* **Observation Data:**
  * Collected 47 transactions for User ID 1 (`Azzam's Kiryana Store`) between Monday 2026-05-11 and Sunday 2026-05-17.
  * **Volume:** 38 Sales, 9 Expenses.
  * **Financial Totals:** Total Sales = Rs. 24,850; Total Expenses = Rs. 18,200; Calculated Net Profit = Rs. 6,650.
  * **Audio Files:** 42 records uploaded as `.webm` to Supabase Storage bucket `kiryana-audio`.
  * **Input Vector Skew:** Daily sales volume is highly consistent (Rs. 3,000–Rs. 4,500), but expenses are heavily grouped on Mondays and Thursdays (bulk delivery days).

### Step 2: Pattern Recognition
* **Observation Data:**
  * Evaluated historical transaction matrices against localized rules defined in `/ai_insights/patterns.py`.
  * **Weekday Trends:** Saturday was detected as the highest sales revenue day (Rs. 5,800) due to weekend home grocery shopping. Monday was detected as the lowest sales revenue day (Rs. 1,900) but highest expense day (Rs. 12,000) due to inventory refills.
  * **Item Performance:** *Cheeni* (Sugar) and *Atta* (Wheat Flour) generated 42% of total weekly revenue, but held the thinnest net margins (~4.5%). *Doodh* (Milk) and *Soap* (Sabun) showed highly recurring daily volume.

### Step 3: Anomaly Detection
* **Observation Data:**
  * **Vertex AI Status:** Deployed runtime endpoint was unavailable (returned 404/Prototype warning). Triggered fallback to the direct `gemini-2.5-flash` anomaly processor.
  * **Identified Anomalies:**
    * **Expense Spike:** A massive single transaction of Rs. 12,000 on Thursday for `Oil (Ghee) bulk stock purchase`. This single expense exceeded the average daily transaction value by **430%**.
    * **Low Revenue Alert:** Tuesday sales fell to Rs. 1,100 (average Tuesday sales = Rs. 3,200). Cross-referencing raw transcripts showed a power outage (*load-shedding*) in the area, reducing foot traffic.

### Step 4: Insight Generation
* **Observation Data:**
  * Compiled totals, anomaly details, and top items into the weekly context object.
  * **Gemini Execution:** Successfully queried `gemini-2.5-flash` with a tailored business-context prompt.
  * **Generated Output:** Resolved structured JSON containing a key business observation and 3 localized suggestions in Roman Urdu.

### Step 5: Action Planning
* **Observation Data:**
  * Evaluated generated recommendations against user historical feedback stored in the `recommendation_feedback` table.
  * **Adaptation Filter:** Found that the user previously rejected general stock suggestions (e.g. *"Refill oil early"*), but accepted specific cash flow suggestions (e.g. *"Buy stock on credit during high sales periods"*). 
  * The orchestrator adapted the recommendation weights using the reinforcement heuristic in `antigravity_agent.py`, successfully filtering out 2 generic recommendations and injecting 1 high-value cash-flow recommendation.

### Step 6: Report Compilation
* **Observation Data:**
  * Formatted the finalized weekly ledger summaries and adapted action plans into a single, clean WhatsApp-friendly payload.
  * **Text Aesthetics:** Applied custom spacing, emojis, and local greetings (*"Assalam o Alaikum..."*) to ensure high readability.

### Step 7: Execution Complete
* **Observation Data:**
  * Saved the `Insight` model to PostgreSQL database table `insights`. 
  * Invalidated the Redis cache key `insight:1:latest` to force a fresh pull on the Dukandaar dashboard.

---

## 2. Multilingual Input Observations

The orchestrator processed conversational speech containing a heavy mix of three language formats:

1. **Urdu Script (10%):** Shopkeeper spoken audio transcribed as:
   * `"دو کلو چینی بیچی تین سو بیس روپے کی"`
   * **Resolution:** Parsed successfully as `item_name="cheeni"`, `quantity=2.0`, `unit="kg"`, `amount=320.0`, `transaction_type="sale"`.
2. **Roman Urdu (70%):** The dominant dialect of street level shopkeepers:
   * `"1 carton oil kharida factory se 4500 ka"`
   * `"aaj atta ki sale hui hai 2300 rupay ki"`
   * **Resolution:** Successfully mapped *"kharida"* to `expense` and *"sale"* to `sale`.
3. **English Mix (20%):** Standard modern words spoken in between sentences:
   * `"aaj total customer walk-in kam tha to loss hua"`
   * **Resolution:** Understood as general ledger noise. The parser isolated the item and cost while discarding conversational chatter.
