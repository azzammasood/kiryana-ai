from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class UserCreate(BaseModel):
    phone_number: str
    name: str = "Dukandaar"


class UserUpdate(BaseModel):
    name: Optional[str] = None
    language: Optional[str] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    phone_number: str
    name: str
    language: str
    notification_day: str
    notification_time: str
    notifications_enabled: bool
    created_at: datetime


class TransactionCreate(BaseModel):
    user_id: int
    item_name: str
    quantity: Optional[float] = None
    unit: Optional[str] = None
    amount: float
    transaction_type: str = Field(pattern="^(sale|expense)$")
    raw_text: Optional[str] = None
    audio_url: Optional[str] = None
    date: date


class TransactionResponse(TransactionCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime


class ParseRequest(BaseModel):
    text: str
    user_id: Optional[int] = None


class ParseResponse(BaseModel):
    item_name: str
    quantity: Optional[float] = None
    unit: Optional[str] = None
    amount: float
    transaction_type: str = Field(pattern="^(sale|expense)$")
    confidence: float


class SummaryResponse(BaseModel):
    today_sales: float
    today_expenses: float
    today_profit: float
    transaction_count: int


class InsightResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    session_id: str
    week_start: date
    week_end: date
    total_sales: float
    total_expenses: float
    profit: float
    top_items: list[dict]
    top_expenses: list[dict] = Field(default_factory=list)
    recommendations: list[str]
    key_insight: str
    report_text: str
    kpis: dict = Field(default_factory=dict)
    created_at: datetime


class AgentTraceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    session_id: str
    step_number: int
    step_label: str
    step_detail: str
    status: str
    created_at: datetime


class VoiceFeedbackCreate(BaseModel):
    user_id: int
    source_transaction_id: Optional[int] = None
    session_id: Optional[str] = None
    raw_transcript: Optional[str] = None
    parsed_payload: Optional[dict] = None
    corrected_payload: Optional[dict] = None
    is_correct: bool


class RecommendationFeedbackCreate(BaseModel):
    user_id: int
    insight_id: int
    recommendation_text: str
    accepted: bool


class InsightAskRequest(BaseModel):
    question: str = Field(min_length=3, max_length=500)


class InsightAskResponse(BaseModel):
    answer: str


class AdaptationKPIResponse(BaseModel):
    user_id: int
    voice_feedback_total: int
    voice_parse_accuracy_pct: float
    recommendation_feedback_total: int
    recommendation_acceptance_pct: float


class NotificationSettings(BaseModel):
    notification_day: Optional[str] = None
    notification_time: Optional[str] = None
    notifications_enabled: Optional[bool] = None


class NotificationSettingsResponse(BaseModel):
    user_id: int
    notification_day: str
    notification_time: str
    notifications_enabled: bool
