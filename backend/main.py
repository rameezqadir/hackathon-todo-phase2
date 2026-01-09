"""
FastAPI main application
[Task]: T-001, T-007
[From]: speckit.plan
"""

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from database import create_db_and_tables
from routes import tasks

load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="Todo API",
    description="RESTful API for todo application",
    version="2.0.0"
)

# Configure CORS
frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[frontend_url, "https://*.vercel.app"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(tasks.router)


@app.on_event("startup")
def on_startup():
    """Create database tables on startup."""
    create_db_and_tables()


@app.get("/")
def read_root():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "message": "Todo API is running",
        "version": "2.0.0"
    }


@app.get("/health")
def health_check():
    """Health check for deployment platforms."""
    return {"status": "ok"}
