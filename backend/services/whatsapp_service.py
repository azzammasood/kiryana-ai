import json
import logging

from twilio.rest import Client

from config import settings


logger = logging.getLogger(__name__)
client = Client(settings.twilio_account_sid, settings.twilio_auth_token)


def send_whatsapp_message(to_number: str, message: str) -> bool:
    if settings.test_mode:
        logger.info("TEST_MODE WhatsApp send simulated to %s", to_number)
        return True
    try:
        number = to_number.replace("+92", "").replace("0", "", 1).strip()
        formatted = f"whatsapp:+92{number}"
        client.messages.create(
            from_=settings.twilio_whatsapp_number,
            to=formatted,
            body=message,
        )
        return True
    except Exception as exc:
        logger.error("WhatsApp send failed: %s", exc)
        return False


def _loads(value, fallback):
    if isinstance(value, str):
        try:
            return json.loads(value)
        except Exception:
            return fallback
    return value or fallback


def format_report_for_whatsapp(insight: dict) -> str:
    top_items = _loads(insight.get("top_items"), [])
    recommendations = _loads(insight.get("recommendations"), [])
    item_text = ", ".join(f"{i.get('item_name')} Rs. {i.get('amount', 0):.0f}" for i in top_items[:3]) or "koi top item nahi"
    rec_text = "\n".join(f"{idx}. {rec}" for idx, rec in enumerate(recommendations[:3], start=1))
    return (
        "Assalam o Alaikum!\n"
        "Aap ki KiryanaAI weekly report ready hai.\n\n"
        f"Bikri: Rs. {float(insight.get('total_sales', 0)):.0f}\n"
        f"Kharcha: Rs. {float(insight.get('total_expenses', 0)):.0f}\n"
        f"Faida: Rs. {float(insight.get('profit', 0)):.0f}\n"
        f"Top items: {item_text}\n\n"
        f"{rec_text}\n\n"
        f"Key insight: {insight.get('key_insight', '')}\n"
        "KiryanaAI"
    )
