import json
import logging
import re
import time
from typing import Any

from twilio.rest import Client

from config import settings


logger = logging.getLogger(__name__)
client = Client(settings.twilio_account_sid, settings.twilio_auth_token)

_SANDBOX_HINT = (
    "Twilio WhatsApp Sandbox: open WhatsApp and send the join code to +1 415 523 8886 "
    "from the same number (+92…) before reports can arrive."
)


def _is_sandbox_sender() -> bool:
    from_number = (settings.twilio_whatsapp_number or "").replace(" ", "")
    return "14155238886" in from_number or "4155238886" in from_number


def _poll_delivery(sid: str, attempts: int = 8, delay: float = 1.0):
    last = None
    for _ in range(attempts):
        last = client.messages(sid).fetch()
        status = (last.status or "").lower()
        if status in ("delivered", "read", "sent"):
            return last, status, None
        if status in ("failed", "undelivered"):
            code = getattr(last, "error_code", None)
            message = getattr(last, "error_message", None) or ""
            return last, status, (code, message)
        time.sleep(delay)
    status = (getattr(last, "status", None) or "queued").lower()
    return last, status, None


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
        sid = getattr(msg, "sid", None)
        polled, status, error_info = _poll_delivery(sid) if sid else (msg, getattr(msg, "status", None), None)
        status = (status or getattr(msg, "status", None) or "").lower()
        detail = ""
        sent = status not in ("failed", "undelivered")
        sandbox = _is_sandbox_sender()

        if error_info:
            code, err_msg = error_info
            detail = str(err_msg or code or status)
            if str(code) == "63015" or "63015" in detail or "sandbox" in detail.lower():
                detail = _SANDBOX_HINT
            sent = False
        elif status in ("failed", "undelivered"):
            detail = f"Twilio status: {status}"
            sent = False
        elif sandbox and status in ("queued", "sending", "accepted"):
            detail = _SANDBOX_HINT
            sent = False

        return {
            "sent": sent,
            "to": display,
            "to_formatted": formatted,
            "sid": sid,
            "status": status,
            "detail": detail,
            "sandbox": sandbox,
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
