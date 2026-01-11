#!/bin/bash

echo "=========================================="
echo "Complete Backend Setup"
echo "=========================================="
echo ""

cd ~/projects/hackathon-todo-phase2/backend

# Step 1: Create virtual environment
echo "1. Creating virtual environment..."
python3.11 -m venv venv
source venv/bin/activate

# Step 2: Create requirements.txt
echo "2. Creating requirements.txt..."
cat > requirements.txt << 'EOF'
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlmodel==0.0.14
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
python-dotenv==1.0.0
pydantic==2.6.0
pydantic-settings==2.1.0
EOF

# Step 3: Install dependencies
echo "3. Installing dependencies (this may take 2-3 minutes)..."
pip install --upgrade pip
pip install -r requirements.txt

# Step 4: Create routes directory
echo "4. Creating directory structure..."
mkdir -p routes
cat > routes/__init__.py << 'EOF'
# Routes package
EOF

# Step 5: Create models.py
echo "5. Creating models.py..."
cat > models.py << 'EOF'
from datetime import datetime
from typing import Optional
from sqlmodel import Field, SQLModel


class Task(SQLModel, table=True):
    __tablename__ = "tasks"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(index=True, nullable=False)
    title: str = Field(max_length=200, nullable=False)
    description: str = Field(default="")
    completed: bool = Field(default=False, index=True)
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)


class TaskCreate(SQLModel):
    title: str = Field(max_length=200, min_length=1)
    description: str = Field(default="", max_length=1000)


class TaskUpdate(SQLModel):
    title: Optional[str] = Field(default=None, max_length=200, min_length=1)
    description: Optional[str] = Field(default=None, max_length=1000)


class TaskResponse(SQLModel):
    id: int
    user_id: str
    title: str
    description: str
    completed: bool
    created_at: datetime
    updated_at: datetime
EOF

# Step 6: Create database.py
echo "6. Creating database.py..."
cat > database.py << 'EOF'
import os
from sqlmodel import create_engine, SQLModel, Session
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable not set")

engine = create_engine(
    DATABASE_URL,
    echo=True,
    pool_pre_ping=True,
)


def create_db_and_tables():
    SQLModel.metadata.create_all(engine)


def get_session():
    with Session(engine) as session:
        yield session
EOF

# Step 7: Create auth.py
echo "7. Creating auth.py..."
cat > auth.py << 'EOF'
import os
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("BETTER_AUTH_SECRET")
if not SECRET_KEY:
    raise ValueError("BETTER_AUTH_SECRET environment variable not set")

ALGORITHM = "HS256"
security = HTTPBearer()


def verify_token(credentials: HTTPAuthorizationCredentials = Security(security)) -> str:
    token = credentials.credentials
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return user_id
        
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def create_access_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=7)
    
    to_encode = {"sub": user_id, "exp": expire}
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return encoded_jwt
EOF

# Step 8: Create routes/tasks.py
echo "8. Creating routes/tasks.py..."
cat > routes/tasks.py << 'EOF'
from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import Session, select
from database import get_session
from models import Task, TaskCreate, TaskUpdate, TaskResponse
from auth import verify_token

router = APIRouter(prefix="/api/{user_id}/tasks", tags=["tasks"])


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    user_id: str,
    task_data: TaskCreate,
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot create tasks for another user"
        )
    
    task = Task(
        user_id=user_id,
        title=task_data.title,
        description=task_data.description
    )
    
    session.add(task)
    session.commit()
    session.refresh(task)
    
    return task


@router.get("", response_model=List[TaskResponse])
def get_tasks(
    user_id: str,
    status_filter: str = Query("all", regex="^(all|pending|completed)$"),
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another user's tasks"
        )
    
    statement = select(Task).where(Task.user_id == user_id)
    
    if status_filter == "pending":
        statement = statement.where(Task.completed == False)
    elif status_filter == "completed":
        statement = statement.where(Task.completed == True)
    
    tasks = session.exec(statement).all()
    
    return tasks


@router.get("/{task_id}", response_model=TaskResponse)
def get_task(
    user_id: str,
    task_id: int,
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another user's tasks"
        )
    
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    return task


@router.put("/{task_id}", response_model=TaskResponse)
def update_task(
    user_id: str,
    task_id: int,
    task_data: TaskUpdate,
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update another user's tasks"
        )
    
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    if task_data.title is not None:
        task.title = task_data.title
    
    if task_data.description is not None:
        task.description = task_data.description
    
    task.updated_at = datetime.now()
    
    session.add(task)
    session.commit()
    session.refresh(task)
    
    return task


@router.patch("/{task_id}/complete", response_model=TaskResponse)
def toggle_complete(
    user_id: str,
    task_id: int,
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update another user's tasks"
        )
    
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    task.completed = not task.completed
    task.updated_at = datetime.now()
    
    session.add(task)
    session.commit()
    session.refresh(task)
    
    return task


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    user_id: str,
    task_id: int,
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete another user's tasks"
        )
    
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    session.delete(task)
    session.commit()
    
    return None
EOF

# Step 9: Create main.py
echo "9. Creating main.py..."
cat > main.py << 'EOF'
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
EOF

# Step 10: Create .env file
echo "10. Creating .env file..."
cat > .env << 'EOF'
DATABASE_URL=postgresql://username:password@host/database?sslmode=require
BETTER_AUTH_SECRET=my-super-secret-key-change-this-to-random-32-characters
FRONTEND_URL=http://localhost:3000
EOF

echo ""
echo "=========================================="
echo "✅ Backend setup complete!"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT: Edit .env file with your Neon database URL"
echo ""
echo "Next steps:"
echo "1. nano .env  (update DATABASE_URL with your Neon connection string)"
echo "2. source venv/bin/activate"
echo "3. uvicorn main:app --reload --port 8000"
echo ""

