"""Pytest suite for ai_voice (schema, prompts, engine with mocked Gemini)."""

from __future__ import annotations

import json
import os
from datetime import datetime
from unittest.mock import MagicMock, patch

import pytest

from ai_voice.engine import (
    VoiceEngine,
    _detect_missing_fields,
    _sanitise_item,
    _strip_json_fences,
)
from ai_voice.prompts import (
    LOW_CONFIDENCE_MESSAGES,
    build_extraction_prompt,
    get_clarification_message,
)
from ai_voice.schema import (
    DetectedLanguage,
    ProcessingStatus,
    TransactionItem,
    TransactionType,
    UnitType,
    VoiceTransactionResult,
)


@pytest.fixture()
def sample_transaction_item() -> dict:
    return {
        "item_name": "atta",
        "item_name_urdu": "آٹا",
        "quantity": 3.0,
        "unit": "kg",
        "price": 300.0,
        "price_per_unit": None,
        "transaction_type": "sale",
        "notes": None,
        "confidence": 0.95,
    }


@pytest.fixture()
def sample_gemini_response() -> str:
    data = {
        "raw_transcript": "aaj teen kg atta becha 300 mein",
        "normalized_transcript": "aaj 3 kg atta becha 300 mein",
        "detected_language": "roman_urdu",
        "dialect_hint": None,
        "confidence_score": 0.92,
        "processing_status": "success",
        "user_friendly_message": None,
        "recorded_at_hint": "aaj",
        "transactions": [
            {
                "item_name": "atta",
                "item_name_urdu": "آٹا",
                "quantity": 3.0,
                "unit": "kg",
                "price": 300.0,
                "price_per_unit": None,
                "transaction_type": "sale",
                "notes": None,
                "confidence": 0.95,
            }
        ],
    }
    return json.dumps(data)


class TestTransactionItemSchema:
    def test_valid_item_parsed_correctly(self, sample_transaction_item: dict) -> None:
        item = TransactionItem(**sample_transaction_item)
        assert item.item_name == "atta"
        assert item.quantity == 3.0
        assert item.unit == UnitType.KG
        assert item.price == 300.0
        assert item.transaction_type == TransactionType.SALE

    def test_price_per_unit_auto_computed(self, sample_transaction_item: dict) -> None:
        sample_transaction_item["price_per_unit"] = None
        item = TransactionItem(**sample_transaction_item)
        assert item.price_per_unit == pytest.approx(100.0)

    def test_price_per_unit_not_overwritten_if_provided(
        self, sample_transaction_item: dict
    ) -> None:
        sample_transaction_item["price_per_unit"] = 99.0
        item = TransactionItem(**sample_transaction_item)
        assert item.price_per_unit == 99.0

    def test_quantity_none_accepted(self, sample_transaction_item: dict) -> None:
        sample_transaction_item["quantity"] = None
        item = TransactionItem(**sample_transaction_item)
        assert item.quantity is None
        assert item.price_per_unit is None

    def test_price_none_accepted(self, sample_transaction_item: dict) -> None:
        sample_transaction_item["price"] = None
        item = TransactionItem(**sample_transaction_item)
        assert item.price is None

    def test_numeric_string_quantity_coerced(self, sample_transaction_item: dict) -> None:
        sample_transaction_item["quantity"] = "3"
        item = TransactionItem(**sample_transaction_item)
        assert item.quantity == 3.0

    def test_invalid_numeric_string_quantity_becomes_none(
        self, sample_transaction_item: dict
    ) -> None:
        sample_transaction_item["quantity"] = "tin kg"
        item = TransactionItem(**sample_transaction_item)
        assert item.quantity is None

    @pytest.mark.parametrize(
        "unit_str,expected",
        [
            ("kg", UnitType.KG),
            ("liter", UnitType.LITER),
            ("bori", UnitType.BORI),
            ("darjan", UnitType.DARJAN),
            ("piece", UnitType.PIECE),
            ("gram", UnitType.GRAM),
            ("packet", UnitType.PACKET),
            ("bundle", UnitType.BUNDLE),
            ("unknown", UnitType.UNKNOWN),
        ],
    )
    def test_all_unit_types_accepted(
        self, sample_transaction_item: dict, unit_str: str, expected: UnitType
    ) -> None:
        sample_transaction_item["unit"] = unit_str
        item = TransactionItem(**sample_transaction_item)
        assert item.unit == expected

    @pytest.mark.parametrize("tx_type", ["sale", "expense", "purchase"])
    def test_all_transaction_types_accepted(
        self, sample_transaction_item: dict, tx_type: str
    ) -> None:
        sample_transaction_item["transaction_type"] = tx_type
        item = TransactionItem(**sample_transaction_item)
        assert item.transaction_type.value == tx_type


class TestVoiceTransactionResultSchema:
    def test_totals_computed_correctly(self, sample_transaction_item: dict) -> None:
        item2 = {**sample_transaction_item, "transaction_type": "expense", "price": 500.0}
        result = VoiceTransactionResult(
            transactions=[
                TransactionItem(**sample_transaction_item),
                TransactionItem(**item2),
            ],
            raw_transcript="test",
            confidence_score=0.9,
            processing_status=ProcessingStatus.SUCCESS,
        )
        assert result.total_sales_pkr == 300.0
        assert result.total_expenses_pkr == 500.0
        assert result.total_purchases_pkr == 0.0

    def test_low_confidence_auto_populates_message(
        self, sample_transaction_item: dict
    ) -> None:
        result = VoiceTransactionResult(
            transactions=[TransactionItem(**sample_transaction_item)],
            raw_transcript="test",
            confidence_score=0.3,
            processing_status=ProcessingStatus.LOW_CONFIDENCE,
            user_friendly_message=None,
        )
        assert result.user_friendly_message is not None
        assert len(result.user_friendly_message) > 10

    def test_high_confidence_no_forced_message(
        self, sample_transaction_item: dict
    ) -> None:
        result = VoiceTransactionResult(
            transactions=[TransactionItem(**sample_transaction_item)],
            raw_transcript="test",
            confidence_score=0.95,
            processing_status=ProcessingStatus.SUCCESS,
        )
        assert result.user_friendly_message is None

    def test_to_api_dict_returns_dict(self, sample_transaction_item: dict) -> None:
        result = VoiceTransactionResult(
            transactions=[TransactionItem(**sample_transaction_item)],
            raw_transcript="aaj teen kg atta becha 300 mein",
            confidence_score=0.92,
            processing_status=ProcessingStatus.SUCCESS,
        )
        api_dict = result.to_api_dict()
        assert isinstance(api_dict, dict)
        assert "transactions" in api_dict
        assert len(api_dict["transactions"]) == 1

    def test_processed_at_is_datetime(self, sample_transaction_item: dict) -> None:
        result = VoiceTransactionResult(
            transactions=[],
            raw_transcript="",
            confidence_score=0.5,
            processing_status=ProcessingStatus.FAILED,
        )
        assert isinstance(result.processed_at, datetime)


class TestPromptBuilder:
    def test_basic_prompt_generated(self) -> None:
        prompt = build_extraction_prompt()
        assert "JSON" in prompt
        assert "confidence" in prompt

    def test_context_hint_included(self) -> None:
        prompt = build_extraction_prompt(context_hint="Trader sells vegetables.")
        assert "vegetables" in prompt

    def test_previous_items_included(self) -> None:
        prompt = build_extraction_prompt(previous_items=["atta", "daal", "chawal"])
        assert "atta" in prompt
        assert "chawal" in prompt

    def test_previous_items_capped_at_20(self) -> None:
        long_list = [f"item_{i}" for i in range(50)]
        prompt = build_extraction_prompt(previous_items=long_list)
        assert "item_0" in prompt
        assert "item_19" in prompt

    def test_no_previous_items(self) -> None:
        prompt = build_extraction_prompt(previous_items=None)
        assert "commonly deals in" not in prompt

    @pytest.mark.parametrize(
        "missing,expected_key",
        [
            (["item_name"], "no_item"),
            (["price"], "no_price"),
            (["quantity"], "no_quantity"),
            ([], "general"),
            (["price", "quantity"], "general"),
        ],
    )
    def test_clarification_message_selection(
        self, missing: list[str], expected_key: str
    ) -> None:
        msg = get_clarification_message(missing)
        assert msg == LOW_CONFIDENCE_MESSAGES[expected_key]

    def test_clarification_message_is_bilingual(self) -> None:
        msg = get_clarification_message([])
        assert "(" in msg
        assert any(ord(c) > 0x0600 for c in msg)


class TestEngineHelpers:
    def test_strip_json_fences_with_backticks(self) -> None:
        raw = '```json\n{"key": "val"}\n```'
        cleaned = _strip_json_fences(raw)
        assert cleaned == '{"key": "val"}'

    def test_strip_json_fences_plain_json(self) -> None:
        raw = '{"key": "val"}'
        assert _strip_json_fences(raw) == raw

    def test_strip_json_fences_no_lang_label(self) -> None:
        raw = '```\n{"key": "val"}\n```'
        cleaned = _strip_json_fences(raw)
        assert cleaned == '{"key": "val"}'

    def test_sanitise_item_invalid_transaction_type(self) -> None:
        item = {"item_name": "atta", "transaction_type": "INVALID", "unit": "kg"}
        sanitised = _sanitise_item(item)
        assert sanitised["transaction_type"] == "sale"

    def test_sanitise_item_invalid_unit(self) -> None:
        item = {"item_name": "atta", "transaction_type": "sale", "unit": "maund"}
        sanitised = _sanitise_item(item)
        assert sanitised["unit"] == "unknown"

    def test_sanitise_item_clamps_confidence(self) -> None:
        item = {
            "item_name": "atta",
            "transaction_type": "sale",
            "unit": "kg",
            "confidence": 5.0,
        }
        sanitised = _sanitise_item(item)
        assert sanitised["confidence"] == 1.0

    def test_sanitise_item_clamps_confidence_negative(self) -> None:
        item = {
            "item_name": "atta",
            "transaction_type": "sale",
            "unit": "kg",
            "confidence": -0.5,
        }
        sanitised = _sanitise_item(item)
        assert sanitised["confidence"] == 0.0

    def test_sanitise_item_empty_strings_become_none(self) -> None:
        item = {
            "item_name": "atta",
            "transaction_type": "sale",
            "unit": "kg",
            "notes": "",
            "item_name_urdu": "",
        }
        sanitised = _sanitise_item(item)
        assert sanitised["notes"] is None
        assert sanitised["item_name_urdu"] is None

    @pytest.mark.parametrize(
        "transactions,expected_missing",
        [
            (
                [{"item_name": "unknown", "price": None, "quantity": None}],
                {"item_name", "price", "quantity"},
            ),
            (
                [{"item_name": "atta", "price": 300.0, "quantity": 3.0}],
                set(),
            ),
            (
                [{"item_name": "atta", "price": None, "quantity": 3.0}],
                {"price"},
            ),
        ],
    )
    def test_detect_missing_fields(
        self, transactions: list[dict], expected_missing: set[str]
    ) -> None:
        result = _detect_missing_fields(transactions)
        assert set(result) == expected_missing


class TestVoiceEngineIntegration:
    def _make_engine_with_response(self, json_response: str) -> VoiceEngine:
        with patch("ai_voice.engine.genai.Client") as mock_client_cls:
            mock_client = MagicMock()
            mock_client_cls.return_value = mock_client
            mock_response = MagicMock()
            mock_response.text = json_response
            mock_client.models.generate_content.return_value = mock_response
            return VoiceEngine(api_key="fake-key")

    def test_standard_roman_urdu_sale(self, sample_gemini_response: str) -> None:
        engine = self._make_engine_with_response(sample_gemini_response)
        with patch.object(
            engine, "_load_audio", return_value=(b"fake_audio", "audio/wav")
        ):
            result = engine.process_audio("dummy.wav")

        assert result.processing_status == ProcessingStatus.SUCCESS
        assert len(result.transactions) == 1
        tx = result.transactions[0]
        assert tx.item_name == "atta"
        assert tx.quantity == 3.0
        assert tx.unit == UnitType.KG
        assert tx.price == 300.0
        assert tx.transaction_type == TransactionType.SALE
        assert result.total_sales_pkr == 300.0

    def test_multiple_transactions_in_one_clip(self) -> None:
        data = {
            "raw_transcript": (
                "teen kg atta becha 300 mein aur do liter ghee kharida 900 mein"
            ),
            "normalized_transcript": None,
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.88,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": None,
            "transactions": [
                {
                    "item_name": "atta",
                    "item_name_urdu": "آٹا",
                    "quantity": 3.0,
                    "unit": "kg",
                    "price": 300.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": None,
                    "confidence": 0.92,
                },
                {
                    "item_name": "ghee",
                    "item_name_urdu": "گھی",
                    "quantity": 2.0,
                    "unit": "liter",
                    "price": 900.0,
                    "price_per_unit": None,
                    "transaction_type": "purchase",
                    "notes": None,
                    "confidence": 0.90,
                },
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert len(result.transactions) == 2
        assert result.total_sales_pkr == 300.0
        assert result.total_purchases_pkr == 900.0
        assert result.transactions[0].item_name == "atta"
        assert result.transactions[1].item_name == "ghee"

    @pytest.mark.parametrize(
        "quantity_val,expected_qty",
        [
            (0.25, 0.25),
            (0.5, 0.5),
            (1.25, 1.25),
            (1.5, 1.5),
            (2.5, 2.5),
        ],
    )
    def test_fraction_quantities(
        self, quantity_val: float, expected_qty: float
    ) -> None:
        data = {
            "raw_transcript": "test fraction",
            "normalized_transcript": None,
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.85,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": None,
            "transactions": [
                {
                    "item_name": "doodh",
                    "item_name_urdu": "دودھ",
                    "quantity": quantity_val,
                    "unit": "liter",
                    "price": 100.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": None,
                    "confidence": 0.88,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.transactions[0].quantity == pytest.approx(expected_qty)

    def test_incomplete_sentence_partial_status(self) -> None:
        data = {
            "raw_transcript": "aaj maine... [cut off]",
            "normalized_transcript": None,
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.35,
            "processing_status": "partial",
            "user_friendly_message": None,
            "recorded_at_hint": "aaj",
            "transactions": [
                {
                    "item_name": "unknown",
                    "item_name_urdu": None,
                    "quantity": None,
                    "unit": "unknown",
                    "price": None,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": "Incomplete sentence",
                    "confidence": 0.30,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.confidence_score < 0.5
        assert result.user_friendly_message is not None
        assert result.processing_status == ProcessingStatus.PARTIAL

    def test_unknown_item_preserved(self) -> None:
        data = {
            "raw_transcript": "woh cheez becha jo thi us ki 200 rupay",
            "normalized_transcript": None,
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.45,
            "processing_status": "low_confidence",
            "user_friendly_message": None,
            "recorded_at_hint": None,
            "transactions": [
                {
                    "item_name": "unknown",
                    "item_name_urdu": None,
                    "quantity": None,
                    "unit": "unknown",
                    "price": 200.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": "Item unclear",
                    "confidence": 0.40,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.transactions[0].item_name == "unknown"
        assert result.user_friendly_message is not None

    def test_background_noise_low_confidence(self) -> None:
        data = {
            "raw_transcript": "[unintelligible background noise]",
            "normalized_transcript": None,
            "detected_language": "mixed",
            "dialect_hint": None,
            "confidence_score": 0.10,
            "processing_status": "low_confidence",
            "user_friendly_message": (
                "آواز واضح نہیں آئی۔ براہ کرم دوبارہ بولیں۔\n"
                "(Audio unclear. Please repeat.)"
            ),
            "recorded_at_hint": None,
            "transactions": [],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.confidence_score < 0.5
        assert result.user_friendly_message is not None
        assert len(result.transactions) == 0

    def test_expense_transaction_type(self) -> None:
        data = {
            "raw_transcript": "bijli ka bill do hazar tha",
            "normalized_transcript": "bijli ka bill 2000 tha",
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.87,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": None,
            "transactions": [
                {
                    "item_name": "bijli bill",
                    "item_name_urdu": "بجلی بل",
                    "quantity": None,
                    "unit": "piece",
                    "price": 2000.0,
                    "price_per_unit": None,
                    "transaction_type": "expense",
                    "notes": None,
                    "confidence": 0.90,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.transactions[0].transaction_type == TransactionType.EXPENSE
        assert result.total_expenses_pkr == 2000.0

    def test_udhaar_note_captured(self) -> None:
        data = {
            "raw_transcript": "panch kg chawal udhaar diya 500 mein",
            "normalized_transcript": "5 kg chawal udhaar diya 500 mein",
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.82,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": None,
            "transactions": [
                {
                    "item_name": "chawal",
                    "item_name_urdu": "چاول",
                    "quantity": 5.0,
                    "unit": "kg",
                    "price": 500.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": "udhaar (credit sale)",
                    "confidence": 0.85,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.transactions[0].notes is not None
        assert "udhaar" in result.transactions[0].notes.lower()

    def test_mixed_urdu_english_code_switching(self) -> None:
        data = {
            "raw_transcript": "aaj 5 dozen eggs sell kiye 900 mein",
            "normalized_transcript": "aaj 5 dozen anda 900 mein",
            "detected_language": "mixed",
            "dialect_hint": None,
            "confidence_score": 0.90,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": "aaj",
            "transactions": [
                {
                    "item_name": "anda",
                    "item_name_urdu": "انڈہ",
                    "quantity": 5.0,
                    "unit": "darjan",
                    "price": 900.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": None,
                    "confidence": 0.92,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.detected_language == DetectedLanguage.MIXED
        assert result.transactions[0].unit == UnitType.DARJAN

    def test_pure_urdu_script_input(self) -> None:
        data = {
            "raw_transcript": "آج تین کلو آٹا بیچا تین سو میں",
            "normalized_transcript": "آج 3 کلو آٹا 300 میں",
            "detected_language": "urdu",
            "dialect_hint": None,
            "confidence_score": 0.88,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": "aaj",
            "transactions": [
                {
                    "item_name": "atta",
                    "item_name_urdu": "آٹا",
                    "quantity": 3.0,
                    "unit": "kg",
                    "price": 300.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": None,
                    "confidence": 0.90,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.detected_language == DetectedLanguage.URDU
        assert result.transactions[0].item_name_urdu == "آٹا"

    def test_gemini_returns_fenced_json_handled(self) -> None:
        data = {
            "raw_transcript": "test",
            "normalized_transcript": None,
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.80,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": None,
            "transactions": [
                {
                    "item_name": "chawal",
                    "item_name_urdu": None,
                    "quantity": 5.0,
                    "unit": "kg",
                    "price": 500.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": None,
                    "confidence": 0.82,
                }
            ],
        }
        fenced_response = f"```json\n{json.dumps(data)}\n```"
        engine = self._make_engine_with_response(fenced_response)
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.processing_status == ProcessingStatus.SUCCESS

    def test_completely_failed_audio(self) -> None:
        with patch("ai_voice.engine.genai.Client") as mock_client_cls:
            mock_client = MagicMock()
            mock_client_cls.return_value = mock_client
            mock_client.models.generate_content.side_effect = RuntimeError("API timeout")
            eng = VoiceEngine(api_key="fake-key")

        with patch.object(eng, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = eng.process_audio("dummy.wav")

        assert result.processing_status == ProcessingStatus.FAILED
        assert result.confidence_score == 0.0
        assert result.user_friendly_message is not None

    def test_file_not_found_raises_gracefully(self) -> None:
        with patch("ai_voice.engine.genai.Client") as mock_client_cls:
            mock_client_cls.return_value = MagicMock()
            eng = VoiceEngine(api_key="fake-key")

        result = eng.process_audio("nonexistent_file_xyz.wav")
        assert result.processing_status == ProcessingStatus.FAILED

    def test_no_api_key_raises_value_error(self) -> None:
        env_backup = os.environ.pop("GEMINI_API_KEY", None)
        try:
            with patch("ai_voice.engine.genai.Client"):
                with pytest.raises(ValueError, match="API key"):
                    VoiceEngine(api_key=None)
        finally:
            if env_backup:
                os.environ["GEMINI_API_KEY"] = env_backup

    def test_large_number_words_do_hazar(self) -> None:
        data = {
            "raw_transcript": "aaj chawal do hazar mein becha",
            "normalized_transcript": "aaj chawal 2000 mein becha",
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.86,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": "aaj",
            "transactions": [
                {
                    "item_name": "chawal",
                    "item_name_urdu": "چاول",
                    "quantity": None,
                    "unit": "unknown",
                    "price": 2000.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": None,
                    "confidence": 0.88,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.transactions[0].price == 2000.0

    def test_price_per_unit_auto_derived_in_result(self) -> None:
        data = {
            "raw_transcript": "10 kg atta 1000 mein becha",
            "normalized_transcript": None,
            "detected_language": "roman_urdu",
            "dialect_hint": None,
            "confidence_score": 0.90,
            "processing_status": "success",
            "user_friendly_message": None,
            "recorded_at_hint": None,
            "transactions": [
                {
                    "item_name": "atta",
                    "item_name_urdu": None,
                    "quantity": 10.0,
                    "unit": "kg",
                    "price": 1000.0,
                    "price_per_unit": None,
                    "transaction_type": "sale",
                    "notes": None,
                    "confidence": 0.92,
                }
            ],
        }
        engine = self._make_engine_with_response(json.dumps(data))
        with patch.object(engine, "_load_audio", return_value=(b"fake", "audio/wav")):
            result = engine.process_audio("dummy.wav")

        assert result.transactions[0].price_per_unit == pytest.approx(100.0)
