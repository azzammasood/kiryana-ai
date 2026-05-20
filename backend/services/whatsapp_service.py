import json
import logging
import re
from typing import Any

from twilio.rest import Client

from config import settings


logger = logging.getLogger(__name__)
client = Client(settings.twilio_account_sid, settings.twilio_auth_token)


def _digits_only(phone: str) -> str:
    return re.sub(r"\D", "", phone or "")


def normalize_pk_whatsapp(phone: str) -> tuple[str, str]:
    """
    Return (twilio_address, display_number) for a Pakistan mobile.
    Accepts 03XXXXXXXXX, 923XXXXXXXXX, +923XXXXXXXXX, etc.
    """
    digits = _digits_only(phone)
    if digits.startswith("92"):
        digits = digits[2:]
    if digits.startswith("0"):
        digits = digits[1:]
    if len(digits) < 10:
        raise ValueError(f"Invalid Pakistan phone number: {phone}")
    national = digits[-10:]
    display = f"0{national}"
    return f"whatsapp:+92{national}", display


def _loads(value: Any, fallback: list) -> list:
    if isinstance(value, str):
        try:
            return json.loads(value)
        except Exception:
            return fallback
    if isinstance(value, list):
        return value
    return fallback


def _recommendation_line(rec: Any) -> str:
    if isinstance(rec, dict):
        ur = (rec.get("ur") or rec.get("text_urdu") or "").strip()
        en = (rec.get("en") or rec.get("text_english") or rec.get("text") or "").strip()
        if ur and en:
            return f"{ur} ({en})"
        return ur or en or str(rec)
    return str(rec).strip()


def insight_to_dict(insight: Any) -> dict:
    return {
        "total_sales": getattr(insight, "total_sales", 0) or 0,
        "total_expenses": getattr(insight, "total_expenses", 0) or 0,
        "profit": getattr(insight, "profit", 0) or 0,
        "top_items": _loads(getattr(insight, "top_items", None), []),
        "recommendations": _loads(getattr(insight, "recommendations", None), []),
        "key_insight": getattr(insight, "key_insight", "") or "",
        "report_text": getattr(insight, "report_text", "") or "",
    }


def format_report_for_whatsapp(insight: dict) -> str:
    top_items = _loads(insight.get("top_items"), [])
    recommendations = _loads(insight.get("recommendations"), [])
    item_text = (
        ", ".join(
            f"{i.get('item_name', i.get('name', 'item'))} Rs. {float(i.get('amount', i.get('total', 0))):.0f}"
            for i in top_items[:3]
            if isinstance(i, dict)
        )
        or "koi top item nahi"
    )
    rec_lines = [
        f"{idx}. {_recommendation_line(rec)}"
        for idx, rec in enumerate(recommendations[:3], start=1)
    ]
    rec_text = "\n".join(rec_lines) or "1. Apni dukaan ke hisaab se agla step choose karen."
    report_body = (insight.get("report_text") or "").strip()
    report_snippet = ""
    if report_body:
        report_snippet = f"\n\n{report_body[:400]}{'…' if len(report_body) > 400 else ''}"

    return (
        "Assalam o Alaikum!\n"
        "Aap ki KiryanaAI weekly report ready hai.\n\n"
        f"Bikri: Rs. {float(insight.get('total_sales', 0)):.0f}\n"
        f"Kharcha: Rs. {float(insight.get('total_expenses', 0)):.0f}\n"
        f"Faida: Rs. {float(insight.get('profit', 0)):.0f}\n"
        f"Top items: {item_text}\n\n"
        f"{rec_text}\n\n"
        f"Key insight: {insight.get('key_insight', '')}"
        f"{report_snippet}\n\n"
        "— KiryanaAI"
    )


def send_whatsapp_message(to_number: str, message: str) -> dict:
    try:
        formatted, display = normalize_pk_whatsapp(to_number)
    except ValueError as exc:
        logger.error("WhatsApp invalid number %s: %s", to_number, exc)
        return {
            "sent": False,
            "to": to_number,
            "to_formatted": "",
            "sid": None,
            "status": None,
            "detail": str(exc),
        }

    if settings.test_mode:
        logger.info("TEST_MODE WhatsApp send simulated to %s", formatted)
        return {
            "sent": True,
            "to": display,
            "to_formatted": formatted,
            "sid": "TEST_MODE",
            "status": "simulated",
            "detail": "Test mode — message not sent to Twilio.",
        }

    try:
        msg = client.messages.create(
            from_=settings.twilio_whatsapp_number,
            to=formatted,
            body=message,
        )
        status = getattr(msg, "status", None)
        error = getattr(msg, "error_message", None)
        detail = ""
        if error:
            detail = str(error)
        elif status in ("failed", "undelivered"):
            detail = f"Twilio status: {status}"
        elif "sandbox" in (settings.twilio_whatsapp_number or "").lower():
            detail = (
                "Twilio sandbox: send the join code from your WhatsApp to the sandbox number first."
            )

        return {
            "sent": status not in ("failed", "undelivered"),
            "to": display,
            "to_formatted": formatted,
            "sid": getattr(msg, "sid", None),
            "status": status,
            "detail": detail,
        }
    except Exception as exc:
        logger.error("WhatsApp send failed to %s: %s", formatted, exc)
        return {
            "sent": False,
            "to": display,
            "to_formatted": formatted,
            "sid": None,
            "status": None,
            "detail": str(exc),
        }
