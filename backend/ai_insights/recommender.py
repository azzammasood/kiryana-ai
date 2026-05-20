"""
Two-layer recommendation engine:
  1. Rule map  — instant, deterministic, no API cost
  2. Gemini fallback — for pattern types not covered by rules
"""

from __future__ import annotations
import os

# ── rule map ──────────────────────────────────────────────────────────────────

_RULES: dict[str, str] = {
    "slow_day": (
        "اس دن اسٹاک کم رکھیں اور غیر ضروری خریداری سے بچیں — خرچہ بچے گا"
    ),
    "margin_shrink": (
        "اس چیز کی قیمت تھوڑی بڑھائیں یا سستا سپلائر تلاش کریں — منافع ٹھیک ہو جائے گا"
    ),
    "dead_stock": (
        "جب تک پرانا اسٹاک ختم نہ ہو، نیا آرڈر نہ کریں"
    ),
    "top_seller": (
        "اس چیز کا اسٹاک ہمیشہ موجود رکھیں تاکہ فروخت مس نہ ہو"
    ),
    "sales_spike": (
        "اس دن پہلے سے تھوڑا اضافی اسٹاک رکھیں اور تیار رہیں"
    ),
}


def _rule_recommendation(pattern: dict) -> str | None:
    return _RULES.get(pattern["type"])


# ── Gemini fallback ────────────────────────────────────────────────────────────

def _gemini_recommendation(pattern: dict) -> str:
    """
    Call Gemini only when no rule covers the pattern type.
    Returns a single Roman Urdu action sentence.
    """
    try:
        import google.generativeai as genai
        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            return "اپنے لین دین کا جائزہ لیں اور ضروری قدم اٹھائیں۔"

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-2.0-flash")

        prompt = (
            "آپ ایک کریانہ اسٹور کے لیے AI اسسٹنٹ ہیں۔ "
            "نیچے ایک بزنس پیٹرن دیا گیا ہے۔ "
            "ایک چھوٹا، کام کا مشورہ اردو میں دیں (1 جملہ، زیادہ سے زیادہ 20 الفاظ)۔\n\n"
            f"پیٹرن: {pattern['message']}"
        )
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception:
        return "اپنے لین دین کا جائزہ لیں اور ضروری قدم اٹھائیں۔"


# ── public entry point ────────────────────────────────────────────────────────

def get_recommendations(patterns: list[dict]) -> list[dict]:
    """
    Returns a list of Recommendation dicts:
      {pattern_type, item, weekday, action_urdu, source}
    source is "rule" or "gemini".
    """
    recommendations = []
    for p in patterns:
        rule = _rule_recommendation(p)
        if rule:
            action = rule
            source = "rule"
        else:
            action = _gemini_recommendation(p)
            source = "gemini"

        recommendations.append({
            "pattern_type": p["type"],
            "item": p.get("item"),
            "weekday": p.get("weekday"),
            "action_urdu": action,
            "source": source,
        })
    return recommendations
