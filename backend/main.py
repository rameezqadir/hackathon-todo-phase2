import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from database import create_db_and_tables
from routes import tasks

load_dotenv()


app = FastAPI(
    title="Todo API",
    description="RESTful API for todo application",
    version="2.0.0"
)



frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://*.vercel.app"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tasks.router)


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


@app.get("/")
def read_root():
    return {
        "status": "healthy",
        "message": "Todo API is running",
        "version": "2.0.0"
    }


@app.get("/health")
def health_check():
    return {"status": "ok"}
