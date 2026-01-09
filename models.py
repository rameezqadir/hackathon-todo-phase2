**Content:**
```python
"""
Database models using SQLModel
[Task]: T-002
[From]: speckit.specify FR-1
"""

from datetime import datetime
from typing import Optional
from sqlmodel import Field, SQLModel


class Task(SQLModel, table=True):
    """Task model for database."""
    
    __tablename__ = "tasks"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(index=True, nullable=False)
    title: str = Field(max_length=200, nullable=False)
    description: str = Field(default="")
    completed: bool = Field(default=False, index=True)
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)


class TaskCreate(SQLModel):
    """Schema for creating a task."""
    title: str = Field(max_length=200, min_length=1)
    description: str = Field(default="", max_length=1000)


class TaskUpdate(SQLModel):
    """Schema for updating a task."""
    title: Optional[str] = Field(default=None, max_length=200, min_length=1)
    description: Optional[str] = Field(default=None, max_length=1000)


class TaskResponse(SQLModel):
    """Schema for task response."""
    id: int
    user_id: str
    title: str
    description: str
    completed: bool
    created_at: datetime
    updated_at: datetime
```

### Step 12: Create Database Connection

```bash
nano database.py
```

**Content:**
```python
"""
Database connection and session management
[Task]: T-003
[From]: speckit.plan §2.1
"""

import os
from sqlmodel import create_engine, SQLModel, Session
from dotenv import load_dotenv

load_dotenv()

# Get database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable not set")

# Create engine
engine = create_engine(
    DATABASE_URL,
    echo=True,  # Set to False in production
    pool_pre_ping=True,  # Verify connections before using
)


def create_db_and_tables():
    """Create all tables in the database."""
    SQLModel.metadata.create_all(engine)


def get_session():
    """Get database session."""
    with Session(engine) as session:
        yield session
