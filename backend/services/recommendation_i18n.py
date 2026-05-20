"""Normalize insight recommendations to bilingual {en, ur} objects."""

from __future__ import annotations

import re

from services import insight_engine

_ARABIC_RE = re.compile(r"[\u0600-\u06FF]")

_RULES_EN: dict[str, str] = {
    "slow_day": "Keep stock lower on this day and avoid unnecessary purchases to save costs.",
    "margin_shrink": "Raise the price slightly or find a cheaper supplier to protect your margin.",
    "dead_stock": "Do not order new stock until the old stock is sold.",
    "top_seller": "Keep this item in stock so you do not miss sales.",
    "sales_spike": "Keep a little extra stock ready for this high-demand day.",
}

_ROMAN_TREND_EN: list[tuple[str, str]] = [
    (
        "Pehle din se aakhri din tak bikri barh rahi hai",
        "Sales are rising from the first day to the last",
    ),
    (
        "Bikri pehle din se kam ho rahi hai",
        "Sales are falling compared to the first day",
    ),
    (
        "Do din ki bikri barabar hai",
        "Sales are steady across the first days — keep top items stocked",
    ),
    (
        "ab tak sab se zyada bikne wali cheez hai",
        "is your top-selling item so far — keep extra stock",
    ),
    (
        "bikri kharchay se zyada hai",
        "Sales are higher than expenses so far — keep logging daily",
    ),
    (
        "Abhi kam entries hain",
        "Few entries so far — log sales and expenses daily with voice",
    ),
    (
        "Rozana 2–3 voice entries",
        "Log 2–3 voice entries daily to build a strong weekly trend",
    ),
]


def _looks_english(text: str) -> bool:
    letters = [ch for ch in text if ch.isalpha()]
    if not letters:
        return True
    latin = sum(1 for ch in letters if ch.isascii())
    return latin / len(letters) >= 0.85 and not _ARABIC_RE.search(text)


def _english_for_urdu_text(ur: str, pattern_type: str | None = None) -> str:
    if pattern_type and pattern_type in _RULES_EN:
        return _RULES_EN[pattern_type]
    for prefix, en_prefix in _ROMAN_TREND_EN:
        if prefix in ur:
            if "taqreeban Rs." in ur or "Rs." in ur:
                amount = re.search(r"Rs\.\s*([0-9.,]+)", ur)
                suffix = f" (about Rs. {amount.group(1)})" if amount else ""
                if "barh rahi" in ur:
                    return f"Sales are rising from the first day to the last{suffix}. Keep this momentum."
                if "kam ho rahi" in ur:
                    return f"Sales are falling from the first day to the last{suffix}. Review pricing and display."
            return en_prefix + "."
    if _looks_english(ur):
        return ur
    return "Review this week's sales and stock based on your latest logs."


def _to_urdu_script(text: str) -> str:
    """Prefer Urdu script for Urdu-mode UI when text is Roman Urdu."""
    if not text or _ARABIC_RE.search(text):
        return text
    lower = text.lower()
    if "ab tak sab se zyada bikne wali cheez" in lower:
        item = text.split(" ab tak")[0].strip()
        amount = re.search(r"Rs\.?\s*([0-9.,]+)", text)
        amt = amount.group(1) if amount else "0"
        return f"{item} اب تک سب سے زیادہ بکنے والی چیز ہے (Rs. {amt})۔ اس کا اسٹاک زیادہ رکھیں۔"
    if "pehle din se aakhri din tak bikri barh rahi" in lower:
        return "پہلے دن سے آخری دن تک فروخت بڑھ رہی ہے۔ اس رجحان کو برقرار رکھیں۔"
    if "bikri pehle din se kam ho rahi" in lower:
        return "فروخت پہلے دن سے کم ہو رہی ہے۔ کاؤنٹر ڈسپلے اور ریٹ بورڈ چیک کریں۔"
    if "do din ki bikri barabar" in lower:
        return "دو دن کی فروخت برابر ہے — ٹاپ آئٹمز کا اسٹاک تیار رکھیں۔"
    if "abhi kam entries hain" in lower:
        return "ابھی کم انٹریز ہیں — روزانہ آواز سے فروخت/خرچ لاگ کریں تاکہ رجحان واضح ہو۔"
    if "rozana" in lower and "voice" in lower:
        return "روزانہ 2–3 وائس انٹریز سے ایک ہفتے میں مضبوط رجحان بنے گا۔"
    return text


def normalize_recommendation(item: str | dict) -> dict[str, str]:
    if isinstance(item, dict):
        ur = (
            item.get("ur")
            or item.get("action_urdu")
            or item.get("text_ur")
            or ""
        ).strip()
        en = (
            item.get("en")
            or item.get("action_en")
            or item.get("action")
            or item.get("text_en")
            or ""
        ).strip()
        pattern_type = item.get("pattern_type")
    else:
        ur = str(item).strip()
        en = ""
        pattern_type = None

    if ur and not en:
        en = _english_for_urdu_text(ur, pattern_type)
    if en and not ur:
        ur = _to_urdu_script(en) if not _looks_english(en) else en
    if ur and not _ARABIC_RE.search(ur):
        ur = _to_urdu_script(ur)
    if not ur and not en:
        ur = en = ""

    return {"en": en, "ur": ur}


def normalize_recommendations_list(items: list) -> list[dict[str, str]]:
    normalized: list[dict[str, str]] = []
    seen: set[str] = set()
    for item in items or []:
        row = normalize_recommendation(item)
        key = row["ur"] or row["en"]
        if not key or key in seen:
            continue
        seen.add(key)
        normalized.append(row)
    return normalized[:3]


def trend_tip_bilingual(transactions_list: list[dict]) -> dict[str, str]:
    ur = insight_engine.short_term_trend_observation(transactions_list)
    return normalize_recommendation(ur)


def recommendation_text(item: str | dict, language: str) -> str:
    row = normalize_recommendation(item)
    lang = (language or "en").lower()
    if lang.startswith("ur"):
        return row["ur"] or row["en"]
    return row["en"] or row["ur"]
