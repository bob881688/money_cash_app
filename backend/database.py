from fastapi import Depends, HTTPException, status
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pathlib import Path
from sqlalchemy import text
from sqlalchemy.exc import (
    DBAPIError,
    InterfaceError,
    OperationalError,
    SQLAlchemyError,
)

from config import Settings
settings = Settings()

engine = create_engine(
    settings.database_url
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def init_resources():
    path = Path("sql/create_table.sql")
    sql = path.read_text(encoding="utf-8")

    # 簡單切分；若你的 SQL 內含函式/觸發器有分號，請改用更健壯的解析或 Alembic
    statements = [s.strip() for s in sql.split(";") if s.strip()]
    with engine.begin() as conn:
        for stmt in statements:
            conn.execute(text(stmt))

    print("資料表已建立完成")

async def close_resources():
    print("關閉資料庫連線")

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