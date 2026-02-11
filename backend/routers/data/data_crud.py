from fastapi import Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.exc import (
    DataError,
    DBAPIError,
    IntegrityError,
    InterfaceError,
    InvalidRequestError,
    OperationalError,
    ProgrammingError,
    SQLAlchemyError,
    StatementError,
)
from sqlalchemy.orm import Session
from fastapi import APIRouter
from pathlib import Path
from pydantic import BaseModel

from database import get_db
from routers.data.depands.data_schemas import *

router = APIRouter()

# 新增 (Create)
@router.post("", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_data(data: CreateDataRequired, db: Session = Depends(get_db)):
    path = Path("sql/Create_data.sql")

    try:
        db.execute(text(path.read_text()), data.model_dump())
        db.commit()

    except Exception as e:
        db.rollback()
        handle_db_exceptions(e)

    return {"message": "資料已成功建立"}

# 查詢 (Read)
@router.get("", response_model= list[dict], status_code=status.HTTP_200_OK)
def get_data(user_id: int, db: Session = Depends(get_db)):
    path = Path("sql/Read_data.sql")

    try:
        data = db.execute(text(path.read_text()), {"user_id": user_id}).mappings().all()
    except Exception as e:
        handle_db_exceptions(e)

    if data is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="查無資料")
    return data

# 更新 (Update)
@router.put("/{log_id}", response_model=dict, status_code=status.HTTP_200_OK)
def update_data(log_id: int, data: UpdateDataRequired, db: Session = Depends(get_db)):
    path = Path("sql/Update_data.sql")

    try:
        db.execute(text(path.read_text()), {"log_id": log_id, **data.model_dump()})
        db.commit()
    except Exception as e:
        db.rollback()
        handle_db_exceptions(e)

    return {"message": "資料已成功更新"}

# 刪除 (Delete)
@router.delete("/{log_id}", response_model=dict, status_code=status.HTTP_200_OK)
def delete_data(log_id: int, db: Session = Depends(get_db)):
    path = Path("sql/Delete_data.sql")

    try:
        db.execute(text(path.read_text()), {"log_id": log_id})
        db.commit()
    except Exception as e:
        db.rollback()
        handle_db_exceptions(e)

    return {"message": "資料已成功刪除"}

# 處理資料庫相關的例外
def handle_db_exceptions(e: Exception):
    if isinstance(e, (OperationalError, InterfaceError)):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="資料庫連線失敗，請稍後再試",
        )
    
    elif isinstance(e, (DBAPIError, SQLAlchemyError)):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="資料庫操作失敗，請稍後再試",
        )
    
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="未知錯誤，請稍後再試",
        )