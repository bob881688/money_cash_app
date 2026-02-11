from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pathlib import Path
from sqlalchemy import text

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