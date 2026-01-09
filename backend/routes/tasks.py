**Content:**
```python
"""
Task API routes
[Task]: T-004, T-006
[From]: speckit.specify FR-2
"""

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
    """
    Create a new task.
    
    [Task]: T-004
    [From]: speckit.specify US-4
    """
    # Verify user_id in URL matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot create tasks for another user"
        )
    
    # Create task
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
    """
    Get all tasks for a user.
    
    [Task]: T-004
    [From]: speckit.specify US-5
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another user's tasks"
        )
    
    # Build query
    statement = select(Task).where(Task.user_id == user_id)
    
    # Apply status filter
    if status_filter == "pending":
        statement = statement.where(Task.completed == False)
    elif status_filter == "completed":
        statement = statement.where(Task.completed == True)
    
    # Execute query
    tasks = session.exec(statement).all()
    
    return tasks


@router.get("/{task_id}", response_model=TaskResponse)
def get_task(
    user_id: str,
    task_id: int,
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    """
    Get a specific task by ID.
    
    [Task]: T-004
    [From]: speckit.specify FR-2
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
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
    """
    Update a task.
    
    [Task]: T-004
    [From]: speckit.specify US-6
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    # Update fields
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
    """
    Toggle task completion status.
    
    [Task]: T-004
    [From]: speckit.specify US-7
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    # Toggle completion
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
    """
    Delete a task.
    
    [Task]: T-004
    [From]: speckit.specify US-8
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    # Delete task
    session.delete(task)
    session.commit()
    
    return None**Content:**
```python
"""
Task API routes
[Task]: T-004, T-006
[From]: speckit.specify FR-2
"""

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
    """
    Create a new task.
    
    [Task]: T-004
    [From]: speckit.specify US-4
    """
    # Verify user_id in URL matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot create tasks for another user"
        )
    
    # Create task
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
    """
    Get all tasks for a user.
    
    [Task]: T-004
    [From]: speckit.specify US-5
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another user's tasks"
        )
    
    # Build query
    statement = select(Task).where(Task.user_id == user_id)
    
    # Apply status filter
    if status_filter == "pending":
        statement = statement.where(Task.completed == False)
    elif status_filter == "completed":
        statement = statement.where(Task.completed == True)
    
    # Execute query
    tasks = session.exec(statement).all()
    
    return tasks


@router.get("/{task_id}", response_model=TaskResponse)
def get_task(
    user_id: str,
    task_id: int,
    session: Session = Depends(get_session),
    token_user_id: str = Depends(verify_token)
):
    """
    Get a specific task by ID.
    
    [Task]: T-004
    [From]: speckit.specify FR-2
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
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
    """
    Update a task.
    
    [Task]: T-004
    [From]: speckit.specify US-6
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    # Update fields
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
    """
    Toggle task completion status.
    
    [Task]: T-004
    [From]: speckit.specify US-7
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    # Toggle completion
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
    """
    Delete a task.
    
    [Task]: T-004
    [From]: speckit.specify US-8
    """
    # Verify user_id matches token
    if user_id != token_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete another user's tasks"
        )
    
    # Get task
    task = session.get(Task, task_id)
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found"
        )
    
    # Verify task belongs to user
    if task.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This task belongs to another user"
        )
    
    # Delete task
    session.delete(task)
    session.commit()
    
    return None
