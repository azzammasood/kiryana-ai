import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

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
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

_CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "*",
    "Access-Control-Allow-Headers": "*",
}


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers=_CORS_HEADERS,
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled error on %s", request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Server error. Dobara try karein."},
        headers=_CORS_HEADERS,
    )


app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(voice.router, prefix="/voice", tags=["voice"])
app.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
app.include_router(insights.router, prefix="/insights", tags=["insights"])
app.include_router(notifications.router, prefix="/notifications", tags=["notifications"])


@app.get("/health")
async def health():
    return {"status": "ok", "app": "KiryanaAI", "version": "1.0.0"}
