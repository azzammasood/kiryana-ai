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
        "Us din stock kam rakhein aur gerech wali cheezein zyada na mangwayein — "
        "kharcha bachega"
    ),
    "margin_shrink": (
        "Is item ki selling price thodi barha dein, ya koi sasta supplier dhundhein — "
        "margin theek ho jaye ga"
    ),
    "dead_stock": (
        "Yeh item filhaal nahi bik raha — jab tak purana stock khatam na ho, "
        "naya order mat karein"
    ),
    "top_seller": (
        "Yeh item acha chal raha hai — stock hamesha available rakhein taake "
        "sale miss na ho"
    ),
    "sales_spike": (
        "Is din bikri zyada hoti hai — pehle se thoda extra stock rakhein "
        "aur ready rahein"
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
            return "Apne transactions ka jaiza lein aur zaroori qadam uthayen."

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-2.0-flash")

        prompt = (
            "Aap ek kiryana store ke liye AI assistant hain. "
            "Neeche ek business pattern diya gaya hai. "
            "Ek chhota, kaam ka mashwara Roman Urdu mein dijiye (1 sentence, max 20 words).\n\n"
            f"Pattern: {pattern['message']}"
        )
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception:
        return "Apne transactions ka jaiza lein aur zaroori qadam uthayen."


# ── public entry point ────────────────────────────────────────────────────────

def get_recommendations(patterns: list[dict]) -> list[dict]:
    """
    Returns a list of Recommendation dicts:
      {pattern_type, item, weekday, action_roman_urdu, source}
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
            "action_roman_urdu": action,
            "source": source,
        })
    return recommendations
