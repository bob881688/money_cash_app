from typing import Annotated

from fastapi import Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session
from fastapi import APIRouter
from pathlib import Path
from pydantic import BaseModel

from database import get_db, handle_db_exceptions
from routers.data.depands.data_schemas import *
from routers.user.depends.security import get_current_active_user
from routers.user.depends.user_schemas import User

router = APIRouter()

CurrentUser = Annotated[User, Depends(get_current_active_user)]

# 新增 (Create)
@router.post("", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_data(
    data: CreateDataRequired,
    current_user: CurrentUser,
    db: Session = Depends(get_db),
):
    path = Path("sql/Create_data.sql")

    try:
        db.execute(
            text(path.read_text()),
            {"user_id": current_user.user_id, **data.model_dump()},
        )
        db.commit()

    except Exception as e:
        db.rollback()
        handle_db_exceptions(e)

    return {"message": "資料已成功建立"}

# 查詢 (Read)
@router.get("", response_model= list[dict], status_code=status.HTTP_200_OK)
def get_data(
    current_user: CurrentUser,
    db: Session = Depends(get_db),
):
    path = Path("sql/Read_data.sql")

    try:
        data = (
            db.execute(text(path.read_text()), {"user_id": current_user.user_id})
            .mappings()
            .all()
        )
    except Exception as e:
        handle_db_exceptions(e)

    if data is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="查無資料")
    return data

# 更新 (Update)
@router.put("/{log_id}", response_model=dict, status_code=status.HTTP_200_OK)
def update_data(
    log_id: int,
    data: UpdateDataRequired,
    current_user: CurrentUser,
    db: Session = Depends(get_db),
):
    path = Path("sql/Update_data.sql")

    try:
        db.execute(
            text(path.read_text()),
            {"log_id": log_id, "user_id": current_user.user_id, **data.model_dump()},
        )
        db.commit()
    except Exception as e:
        db.rollback()
        handle_db_exceptions(e)

    return {"message": "資料已成功更新"}

# 刪除 (Delete)
@router.delete("/{log_id}", response_model=dict, status_code=status.HTTP_200_OK)
def delete_data(
    log_id: int,
    current_user: CurrentUser,
    db: Session = Depends(get_db),
):
    path = Path("sql/Delete_data.sql")

    try:
        db.execute(
            text(path.read_text()),
            {"log_id": log_id, "user_id": current_user.user_id},
        )
        db.commit()
    except Exception as e:
        db.rollback()
        handle_db_exceptions(e)

    return {"message": "資料已成功刪除"}
