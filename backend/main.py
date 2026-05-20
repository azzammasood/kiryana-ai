import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import engine
from routes import insights, notifications, transactions, users, voice


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("KiryanaAI backend starting...")
    logger.info("Database schema is managed by Alembic migrations.")
    yield
    logger.info("KiryanaAI backend shutting down.")
    await engine.dispose()


app = FastAPI(title="KiryanaAI API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(voice.router, prefix="/voice", tags=["voice"])
app.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
app.include_router(insights.router, prefix="/insights", tags=["insights"])
app.include_router(notifications.router, prefix="/notifications", tags=["notifications"])


@app.get("/health")
async def health():
    return {"status": "ok", "app": "KiryanaAI", "version": "1.0.0"}
