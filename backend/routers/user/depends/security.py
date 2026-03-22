from datetime import datetime, timedelta, timezone
from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import jwt
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash
from pathlib import Path
from sqlalchemy import text
from sqlalchemy.orm import Session

from config import Settings
from database import get_db, handle_db_exceptions
from routers.user.depends.oauth_schemas import TokenData
from routers.user.depends.user_schemas import User, UserPasswordInDB

settings = Settings()

# openssl rand -hex 32
password_hash_method = PasswordHash.recommended()
DUMMY_HASH = password_hash_method.hash("dummypassword")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verify_password(plain_password, hashed_password):
    try:
        return password_hash_method.verify(plain_password, hashed_password)
    except Exception:
        return False


def get_password_hash(password):
    return password_hash_method.hash(password)


def get_user(username: str, db: Session):
    path = Path("sql/Read_user.sql")

    try:
        data = db.execute(text(path.read_text()), {"username": username}).mappings().first()
    except Exception as e:
        handle_db_exceptions(e)

    if data is None:
        return None

    return UserPasswordInDB(**data)


def authenticate_user(username: str, password: str, db: Session):
    user = get_user(username, db)
    if not user:
        verify_password(password, DUMMY_HASH)
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user


def create_access_token(data: dict):
    to_encode = data.copy()

    expires_delta = timedelta(days=settings.ACCESS_TOKEN_EXPIRE_DAYS)
    expire = datetime.now(timezone.utc) + expires_delta

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Session = Depends(get_db),
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except InvalidTokenError:
        raise credentials_exception
    user = get_user(username=token_data.username, db=db)
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)],
):
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user
