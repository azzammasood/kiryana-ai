from __future__ import annotations

import asyncio
import importlib.util
import json
import logging
import re
import sys
from datetime import date, timedelta
from pathlib import Path

import google.generativeai as genai
from google.api_core.exceptions import ResourceExhausted

from config import Settings, settings
from services import insight_engine


logger = logging.getLogger(__name__)
MODEL_NAME = "gemini-2.5-flash"

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

def _configure_genai() -> None:
    """Reload API key from .env on each call (no full server restart needed in dev)."""
    genai.configure(api_key=Settings().gemini_api_key)


def _load_branch_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def _model(system_instruction: str | None = None):
    _configure_genai()
    return genai.GenerativeModel(MODEL_NAME, system_instruction=system_instruction)


def _context_fallback_answer(context: dict) -> str:
    summary = context.get("summary") or {}
    profit = float(summary.get("profit") or 0)
    sales = float(summary.get("total_sales") or 0)
    expenses = float(summary.get("total_expenses") or 0)
    return (
        "AI quota busy hai abhi — ye rule-based jawab hai. "
        f"Is hafte bikri Rs. {sales:.0f}, kharcha Rs. {expenses:.0f}, profit Rs. {profit:.0f}. "
        "Top items ka stock check karein aur subah shop open time par fresh maal rakhein."
    )


def _strip_json_fences(text: str) -> str:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)
    return cleaned.strip()


def _response_text(response) -> str:
    try:
        return (response.text or "").strip()
    except ValueError as exc:
        logger.warning("Gemini returned no text part: %s", exc)
        return ""


async def transcribe_audio(audio_bytes: bytes, mime_type: str) -> str:
    if settings.test_mode:
        return "do kilo cheeni bechi 320 rupay"

    prompt = (
        "Transcribe this audio exactly as spoken. The speaker is using Urdu, Roman Urdu, "
        "or a mix with English. Return only the transcription, nothing else. Do not translate."
    )

    normalized_mime = (mime_type or "audio/webm").split(";")[0].strip().lower()
    if normalized_mime == "video/webm":
        normalized_mime = "audio/webm"

    def _call() -> str:
        response = _model().generate_content(
            [
                {"mime_type": normalized_mime, "data": audio_bytes},
                prompt,
            ],
            generation_config={"temperature": 0.0},
        )
        return _response_text(response)

    return await asyncio.to_thread(_call)


def _normalize_voice_transaction(
    item: dict,
    raw_transcript: str,
    audio_url: str | None = None,
    transaction_date: date | None = None,
) -> dict:
    tx_type = item.get("transaction_type") or "expense"
    if tx_type == "purchase":
        tx_type = "expense"
    unit = item.get("unit")
    if unit == "unknown":
        unit = None
    return {
        "item_name": item.get("item_name") or item.get("item_name_urdu") or "unknown",
        "quantity": item.get("quantity"),
        "unit": unit,
        "amount": float(item.get("price") or 0),
        "transaction_type": tx_type,
        "confidence": float(item.get("confidence") or 0),
        "raw_text": raw_transcript,
        "audio_url": audio_url,
        "transaction_date": (transaction_date or date.today()).isoformat(),
    }


def _infer_dates(raw_transcript: str, count: int) -> list[date]:
    lowered = raw_transcript.lower()
    today = date.today()
    yesterday = today - timedelta(days=1)
    if count >= 2 and "kal" in lowered and "aaj" in lowered:
        return [yesterday, today, *([today] * max(0, count - 2))]
    if "kal" in lowered:
        return [yesterday for _ in range(count)]
    return [today for _ in range(count)]


async def process_voice_audio(audio_bytes: bytes, mime_type: str, audio_url: str | None = None) -> dict:
    if settings.test_mode:
        parsed = await parse_transaction(await transcribe_audio(audio_bytes, mime_type))
        return {
            "raw_transcript": "do kilo cheeni bechi 320 rupay",
            "detected_language": "roman_urdu",
            "confidence_score": parsed["confidence"],
            "processing_status": "success",
            "transactions": [{**parsed, "raw_text": "do kilo cheeni bechi 320 rupay", "audio_url": audio_url}],
            "engine": "test-mode",
        }

    normalized_mime = (mime_type or "audio/webm").split(";")[0].strip().lower()
    if normalized_mime == "video/webm":
        normalized_mime = "audio/webm"

    def _call() -> dict:
        prompts = _load_branch_module("ai_voice_prompts_direct", REPO_ROOT / "ai_voice" / "prompts.py")
        schema = _load_branch_module("ai_voice_schema_direct", REPO_ROOT / "ai_voice" / "schema.py")

        response = _model(prompts.MASTER_SYSTEM_PROMPT).generate_content(
            [
                {"mime_type": normalized_mime, "data": audio_bytes},
                prompts.build_extraction_prompt(),
            ],
            generation_config={"temperature": 0.0, "response_mime_type": "application/json"},
        )
        raw_json = _strip_json_fences(_response_text(response) or "{}")
        if not raw_json:
            raw_json = "{}"
        parsed = json.loads(raw_json) if raw_json else {}
        for item in parsed.get("transactions", []) or []:
            if isinstance(item, dict) and not item.get("transaction_type"):
                lowered = (parsed.get("raw_transcript") or parsed.get("normalized_transcript") or "").lower()
                if any(w in lowered for w in ("bechi", "becha", "bikri", "sold", "sale")):
                    item["transaction_type"] = "sale"
                else:
                    item["transaction_type"] = "expense"
        return schema.VoiceTransactionResult.model_validate(parsed).to_api_dict()

    result = await asyncio.to_thread(_call)
    raw_transcript = result.get("raw_transcript") or result.get("normalized_transcript") or ""
    txs = result.get("transactions", [])
    inferred_dates = _infer_dates(raw_transcript, len(txs))
    result["transactions"] = [
        _normalize_voice_transaction(item, raw_transcript, audio_url, inferred_dates[idx])
        for idx, item in enumerate(txs)
    ]
    result["engine"] = "ai-voice-prompts/gemini-2.5-flash"
    return result


async def parse_transaction(text: str) -> dict:
    if settings.test_mode:
        lowered = text.lower()
        return {
            "item_name": "cheeni" if "cheeni" in lowered else "atta",
            "quantity": 2 if "do" in lowered or "2" in lowered else 1,
            "unit": "kg",
            "amount": 320 if "320" in lowered else 100,
            "transaction_type": "expense" if "kharida" in lowered or "kharcha" in lowered else "sale",
            "confidence": 0.96,
        }

    system = (
        "You are a parser for a Pakistani kiryana store expense tracker. Extract transaction "
        "details from Urdu, Roman Urdu, or English. Return ONLY valid JSON, no markdown, no explanation."
    )
    prompt = f'''
Parse this transaction: "{text}"

Return ONLY:
{{
  "item_name": "product name",
  "quantity": number or null,
  "unit": "kg/gram/litre/piece/dozen/box or null",
  "amount": number in PKR,
  "transaction_type": "sale" or "expense",
  "confidence": 0.0 to 1.0
}}

Rules:
- becha/bechein/sold/bikri -> "sale"
- kharida/khareeda/bought/kharcha -> "expense"
- amount is a plain number, no currency symbol
- item_name is the product only, no quantities
'''

    async def _attempt(strict: bool = False) -> dict:
        final_prompt = prompt if not strict else f"{prompt}\nReturn raw JSON only. No fences. No prose."

        def _call() -> str:
            response = _model(system).generate_content(
                final_prompt,
                generation_config={"temperature": 0.1, "response_mime_type": "application/json"},
            )
            return _response_text(response)

        raw = await asyncio.to_thread(_call)
        return json.loads(_strip_json_fences(raw))

    try:
        data = await _attempt()
    except Exception:
        data = await _attempt(strict=True)

    required = {"item_name", "amount", "transaction_type", "confidence"}
    missing = required - set(data)
    if missing:
        raise ValueError(f"Gemini parse response missing fields: {', '.join(sorted(missing))}")
    return data


async def generate_insights(summary: dict) -> dict:
    if settings.test_mode:
        return {
            "recommendations": [
                "Cheeni aur atta ka stock weekend se pehle refill karein.",
                "Kharcha daily note karein taake profit clear rahe.",
                "Top selling items ko counter ke qareeb rakhein.",
            ],
            "key_insight": "Is hafte sales expenses se zyada rahi, profit positive hai.",
            "report_text": (
                "Assalam o Alaikum, is hafte aap ki dukaan ki sales achi rahi. "
                f"Total bikri Rs. {summary['total_sales']:.0f} aur kharcha Rs. {summary['total_expenses']:.0f} raha. "
                f"Net profit Rs. {summary['profit']:.0f} bana. Top items par stock focus rakhein."
            ),
        }

    system = (
        "You are a business advisor for small Pakistani kiryana stores. Give practical advice "
        "in simple Urdu mixed with English. Return only valid JSON."
    )
    prompt = f'''
Weekly data for a kiryana store:
Total Sales: Rs. {summary["total_sales"]}
Total Expenses: Rs. {summary["total_expenses"]}
Net Profit: Rs. {summary["profit"]}
Top items: {summary["top_items"]}
All transactions: {summary["transactions_list"]}

Return ONLY:
{{
  "recommendations": ["tip 1", "tip 2", "tip 3"],
  "key_insight": "single most important observation",
  "report_text": "4-5 sentence WhatsApp-ready Urdu summary starting with Assalam o Alaikum"
}}
'''

    def _call() -> str:
        response = _model(system).generate_content(
            prompt,
            generation_config={"temperature": 0.35, "response_mime_type": "application/json"},
        )
        return _response_text(response)

    raw = await asyncio.to_thread(_call)
    if not raw:
        return {
            "recommendations": [
                "Top selling items ka stock daily check karein.",
                "Expenses ko daily record karein taake profit clear rahe.",
                "High demand items ke liye reorder point set karein.",
            ],
            "key_insight": "Transactions record ho gaye hain; AI response empty tha, rule-based fallback use hua.",
            "report_text": (
                "Assalam o Alaikum, is hafte ka report ready hai. "
                f"Total bikri Rs. {summary['total_sales']:.0f}, kharcha Rs. {summary['total_expenses']:.0f}, "
                f"aur net profit Rs. {summary['profit']:.0f} raha. Stock aur expenses par nazar rakhein."
            ),
        }
    cleaned = _strip_json_fences(raw)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        return {
            "recommendations": [
                "Top selling items ka stock daily check karein.",
                "Expenses ko daily record karein taake profit clear rahe.",
                "High demand items ke liye reorder point set karein.",
            ],
            "key_insight": "Transactions record ho gaye hain; AI response parse nahi hui, fallback use hua.",
            "report_text": (
                "Assalam o Alaikum, is hafte ka report ready hai. "
                f"Total bikri Rs. {summary['total_sales']:.0f}, kharcha Rs. {summary['total_expenses']:.0f}, "
                f"aur net profit Rs. {summary['profit']:.0f} raha."
            ),
        }


def _normalize_transactions_list(transactions: list) -> list[dict]:
    rows: list[dict] = []
    for t in transactions:
        if isinstance(t, dict):
            rows.append(t)
        else:
            rows.append(
                {
                    "item_name": getattr(t, "item_name", "item"),
                    "amount": float(getattr(t, "amount", 0) or 0),
                    "transaction_type": getattr(t, "transaction_type", "sale"),
                    "date": str(getattr(t, "date", "")),
                }
            )
    return rows


def _sanitize_trend_text(text: str, fallback: str) -> str:
    cleaned = (text or "").strip()
    lower = cleaned.lower()
    if not cleaned:
        return fallback
    if any(
        phrase in lower
        for phrase in (
            "insufficient",
            "not enough data",
            "30-day",
            "30 day",
            "unable to",
            "cannot analyze",
        )
    ):
        return fallback
    return cleaned


async def detect_anomalies(transactions: list) -> str:
    if settings.test_mode:
        return "Cheeni ki demand repeat ho rahi hai; stock level check karna behtar hoga."

    rows = _normalize_transactions_list(transactions)
    fallback = insight_engine.short_term_trend_observation(rows)
    if not rows:
        return fallback

    unique_days = {str(r.get("date") or "")[:10] for r in rows if r.get("date")}
    prompt = (
        f"You advise a Pakistani kiryana shop. The ledger has {len(rows)} entries across "
        f"{max(len(unique_days), 1)} day(s) — short history is OK.\n"
        "Return ONE short practical tip in Roman Urdu only (max 2 sentences).\n"
        "Never say insufficient data, never mention 30-day requirements, never use English.\n\n"
        f"{json.dumps(rows, default=str, ensure_ascii=False)}"
    )

    def _call() -> str:
        response = _model().generate_content(prompt, generation_config={"temperature": 0.2})
        return _response_text(response)

    raw = await asyncio.to_thread(_call)
    return _sanitize_trend_text(raw, fallback)


async def ask_finance_question(question: str, context: dict) -> str:
    summary = context.get("summary") or {}
    if settings.test_mode:
        return (
            "Aap ke sawal ka jawab: atta bechnay ke liye counter par clear rate board lagayein, "
            "regular customers ko WhatsApp par rate bhejein, aur subah 9-11 baje fresh stock rakhein."
        )

    prompt = f"""
You advise a small Pakistani kiryana store owner.
Answer in Roman Urdu (simple, practical, max 4 short sentences).
Question: {question}

Weekly summary:
- Sales: Rs. {summary.get('total_sales', 0)}
- Expenses: Rs. {summary.get('total_expenses', 0)}
- Profit: Rs. {summary.get('profit', 0)}
- Top sales items: {summary.get('top_items', [])}
- Top expenses: {summary.get('top_expenses', [])}
Latest insight: {context.get('key_insight', '')}
Recommendations: {context.get('recommendations', [])}
"""

    def _call() -> str:
        response = _model(
            "You are a helpful kiryana finance coach. Keep answers actionable and local."
        ).generate_content(prompt, generation_config={"temperature": 0.45})
        return _response_text(response)

    try:
        answer = await asyncio.to_thread(_call)
        return answer or "Filhaal jawab generate nahi ho saka. Thori dair baad dobara try karein."
    except ResourceExhausted:
        return _context_fallback_answer(context)
    except Exception as exc:
        if "quota" in str(exc).lower() or "429" in str(exc):
            return _context_fallback_answer(context)
        raise


def _finalize_ask_transcription(result: dict[str, str], question_hint: str | None) -> dict[str, str]:
    hint = (question_hint or "").strip()
    tx = (result.get("transcription") or "").strip()
    lower = tx.lower()
    weak = (
        not tx
        or len(tx) < 12
        or "kuch aisa" in lower
        or "something like" in lower
        or lower in {"...", "audio", "unclear"}
    )
    if hint and weak:
        result["transcription"] = hint
    return result


async def ask_finance_from_audio(
    audio_bytes: bytes, mime_type: str, context: dict, question_hint: str | None = None
) -> dict[str, str]:
    summary = context.get("summary") or {}
    hint = (question_hint or "").strip()
    if settings.test_mode:
        return _finalize_ask_transcription(
            {
                "transcription": hint or "mera munafa kitna hai",
                "answer": (
                    "Aap ke sawal ka jawab: atta bechnay ke liye counter par clear rate board lagayein, "
                    "regular customers ko WhatsApp par rate bhejein, aur subah 9-11 baje fresh stock rakhein."
                ),
            },
            hint,
        )

    normalized_mime = (mime_type or "audio/webm").split(";")[0].strip().lower()
    if normalized_mime == "video/webm":
        normalized_mime = "audio/webm"

    hint_block = (
        f"\nUser selected question (use if audio unclear): {hint}\n"
        if hint
        else ""
    )
    prompt = f"""
Listen to the shopkeeper audio (Urdu / Roman Urdu / English mix).
{hint_block}
Tasks:
1. Transcribe exactly what was spoken (Roman Urdu). If a selected question is given and audio is unclear, put that question in transcription.
2. Answer their business question in Roman Urdu (simple, practical, max 4 short sentences).

Return ONLY valid JSON:
{{"transcription":"...","answer":"..."}}

Weekly summary:
- Sales: Rs. {summary.get('total_sales', 0)}
- Expenses: Rs. {summary.get('total_expenses', 0)}
- Profit: Rs. {summary.get('profit', 0)}
- Top sales items: {summary.get('top_items', [])}
- Top expenses: {summary.get('top_expenses', [])}
Latest insight: {context.get('key_insight', '')}
Recommendations: {context.get('recommendations', [])}
"""

    def _call() -> dict[str, str]:
        response = _model(
            "You are a helpful kiryana finance coach. Keep answers actionable and local."
        ).generate_content(
            [
                {"mime_type": normalized_mime, "data": audio_bytes},
                prompt,
            ],
            generation_config={"temperature": 0.4},
        )
        raw = _strip_json_fences(_response_text(response))
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, dict):
                return {
                    "transcription": str(parsed.get("transcription") or "").strip(),
                    "answer": str(parsed.get("answer") or "").strip(),
                }
        except json.JSONDecodeError:
            pass
        return {"transcription": raw[:240], "answer": raw[:500]}

    try:
        result = await asyncio.to_thread(_call)
        return _finalize_ask_transcription(result, hint)
    except ResourceExhausted:
        return _finalize_ask_transcription(
            {
                "transcription": "",
                "answer": _context_fallback_answer(context),
            },
            hint,
        )
    except Exception as exc:
        err = str(exc).lower()
        if "quota" in err or "429" in err or "resource_exhausted" in err:
            return _finalize_ask_transcription(
                {
                    "transcription": "",
                    "answer": _context_fallback_answer(context),
                },
                hint,
            )
        raise
