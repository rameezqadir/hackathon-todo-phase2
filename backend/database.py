"""
Database connection and session management
"""

import os
from sqlmodel import create_engine, SQLModel, Session
from dotenv import load_dotenv

load_dotenv()

# Get database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("postgresql://neondb_owner:npg_bwCBruq74ePN@ep-odd-poetry-a1n2do48-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require'")

# Create engine
engine = create_engine(
    DATABASE_URL,
    echo=True,
    pool_pre_ping=True,
)


def create_db_and_tables():
    """Create all tables in the database."""
    SQLModel.metadata.create_all(engine)


def get_session():
    """Get database session."""
    with Session(engine) as session:
        yield session
