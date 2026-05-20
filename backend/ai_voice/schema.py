"""Pydantic models for KiryanaAI voice transaction parsing (API contract)."""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field, field_validator, model_validator


class TransactionType(str, Enum):
    """Canonical transaction categories understood by the ledger backend."""

    SALE = "sale"
    EXPENSE = "expense"
    PURCHASE = "purchase"


class UnitType(str, Enum):
    """Physical units handled in Pakistani retail trade."""

    KG = "kg"
    GRAM = "gram"
    LITER = "liter"
    ML = "ml"
    BORI = "bori"
    DARJAN = "darjan"
    PIECE = "piece"
    DOZEN = "dozen"
    PACKET = "packet"
    BUNDLE = "bundle"
    UNKNOWN = "unknown"


class DetectedLanguage(str, Enum):
    """Language profile detected in the audio clip."""

    URDU = "urdu"
    ENGLISH = "english"
    ROMAN_URDU = "roman_urdu"
    MIXED = "mixed"


class ProcessingStatus(str, Enum):
    """Top-level status of the voice processing pipeline."""

    SUCCESS = "success"
    LOW_CONFIDENCE = "low_confidence"
    PARTIAL = "partial"
    FAILED = "failed"


class TransactionItem(BaseModel):
    """One line-item extracted from the voice clip."""

    item_name: str = Field(
        ...,
        description="Canonical item name in English or transliterated Roman Urdu.",
        min_length=1,
        max_length=120,
    )
    item_name_urdu: Optional[str] = Field(
        default=None,
        description="Item name in Urdu script when present in audio.",
    )
    quantity: Optional[float] = Field(
        default=None,
        description="Numeric quantity; fractional words mapped by the model.",
        ge=0,
    )
    unit: UnitType = Field(
        default=UnitType.UNKNOWN,
        description="Physical unit of measurement.",
    )
    price: Optional[float] = Field(
        default=None,
        description="Total transaction amount in PKR.",
        ge=0,
    )
    price_per_unit: Optional[float] = Field(
        default=None,
        description="Derived price-per-unit when quantity and price are known.",
        ge=0,
    )
    transaction_type: TransactionType = Field(
        ...,
        description="sale, purchase, or expense.",
    )
    notes: Optional[str] = Field(
        default=None,
        description="Extra context: udhaar, naqad, time hints, etc.",
        max_length=300,
    )
    confidence: float = Field(
        default=1.0,
        description="Item-level confidence (0.0–1.0).",
        ge=0.0,
        le=1.0,
    )

    @model_validator(mode="after")
    def _compute_price_per_unit(self) -> TransactionItem:
        if (
            self.price is not None
            and self.quantity is not None
            and self.quantity > 0
            and self.price_per_unit is None
        ):
            object.__setattr__(
                self,
                "price_per_unit",
                round(self.price / self.quantity, 4),
            )
        return self

    @field_validator("transaction_type", mode="before")
    @classmethod
    def _coerce_transaction_type(cls, value: object) -> TransactionType:
        if value is None or value == "":
            return TransactionType.EXPENSE
        if isinstance(value, TransactionType):
            return value
        text = str(value).lower().strip()
        if text in ("sale", "expense", "purchase"):
            return TransactionType(text)
        if text in ("sell", "sold", "bechi", "becha", "bikri", "income"):
            return TransactionType.SALE
        if text in ("buy", "bought", "kharida", "kharcha", "purchase", "cost"):
            return TransactionType.EXPENSE if text != "purchase" else TransactionType.PURCHASE
        return TransactionType.EXPENSE

    @field_validator("quantity", mode="before")
    @classmethod
    def _coerce_quantity(cls, value: object) -> Optional[float]:
        if value is None:
            return None
        try:
            return float(value)  # type: ignore[arg-type]
        except (TypeError, ValueError):
            return None

    @field_validator("price", "price_per_unit", mode="before")
    @classmethod
    def _coerce_price(cls, value: object) -> Optional[float]:
        if value is None:
            return None
        try:
            return float(value)  # type: ignore[arg-type]
        except (TypeError, ValueError):
            return None


class VoiceTransactionResult(BaseModel):
    """Structured output returned by the ai_voice engine."""

    transactions: List[TransactionItem] = Field(
        default_factory=list,
        description="Parsed transaction line-items.",
    )
    raw_transcript: str = Field(
        default="",
        description="Transcript as returned by Gemini.",
    )
    normalized_transcript: Optional[str] = Field(
        default=None,
        description="Cleaned transcript if the model provides one.",
    )
    detected_language: DetectedLanguage = Field(
        default=DetectedLanguage.MIXED,
        description="Primary language profile.",
    )
    dialect_hint: Optional[str] = Field(
        default=None,
        description="Regional dialect hint if inferable.",
    )
    audio_duration_seconds: Optional[float] = Field(
        default=None,
        description="Clip duration in seconds when known.",
        ge=0,
    )
    confidence_score: float = Field(
        ...,
        description="Overall confidence (0.0–1.0).",
        ge=0.0,
        le=1.0,
    )
    user_friendly_message: Optional[str] = Field(
        default=None,
        description="Bilingual message when confidence is low.",
    )
    processing_status: ProcessingStatus = Field(
        ...,
        description="Pipeline outcome.",
    )
    error_detail: Optional[str] = Field(
        default=None,
        description="Technical error detail when status is failed.",
    )
    recorded_at_hint: Optional[str] = Field(
        default=None,
        description="Time reference from speech (aaj, kal, subah, …).",
    )
    processed_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="UTC processing timestamp.",
    )
    total_sales_pkr: float = Field(
        default=0.0,
        description="Sum of SALE prices in this clip.",
    )
    total_expenses_pkr: float = Field(
        default=0.0,
        description="Sum of EXPENSE prices in this clip.",
    )
    total_purchases_pkr: float = Field(
        default=0.0,
        description="Sum of PURCHASE prices in this clip.",
    )

    @model_validator(mode="after")
    def _compute_totals(self) -> VoiceTransactionResult:
        self.total_sales_pkr = sum(
            t.price for t in self.transactions
            if t.transaction_type == TransactionType.SALE and t.price is not None
        )
        self.total_expenses_pkr = sum(
            t.price for t in self.transactions
            if t.transaction_type == TransactionType.EXPENSE and t.price is not None
        )
        self.total_purchases_pkr = sum(
            t.price for t in self.transactions
            if t.transaction_type == TransactionType.PURCHASE and t.price is not None
        )
        return self

    @model_validator(mode="after")
    def _validate_confidence_message(self) -> VoiceTransactionResult:
        if self.confidence_score < 0.5 and not self.user_friendly_message:
            object.__setattr__(
                self,
                "user_friendly_message",
                "آواز واضح نہیں تھی۔ براہ کرم دوبارہ بولیں یا لکھ کر بتائیں۔\n"
                "(We couldn't understand clearly. Please repeat or type your transaction.)",
            )
        return self

    def to_api_dict(self) -> dict:
        """Serialize for downstream APIs (drops technical-only fields)."""
        return self.model_dump(
            mode="json",
            exclude={"error_detail"},
            exclude_none=False,
        )
