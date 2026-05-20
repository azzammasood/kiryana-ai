from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str
    redis_url: str
    gemini_api_key: str
    google_cloud_project: str
    google_cloud_location: str = "us-central1"
    google_application_credentials: str
    twilio_account_sid: str
    twilio_auth_token: str
    twilio_whatsapp_number: str
    supabase_url: str
    supabase_service_key: str
    supabase_audio_bucket: str = "kiryana-audio"
    test_mode: bool = False

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
