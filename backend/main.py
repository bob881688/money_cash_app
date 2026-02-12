from fastapi import FastAPI, status
from contextlib import asynccontextmanager
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from starlette.requests import Request

from database import init_resources, close_resources
from routers.data.data_crud import router as data_router

@asynccontextmanager
async def app_lifespan(app: FastAPI):
    # Startup 階段
    await init_resources()
    try:
        # 這個 yield 之間的時間就是應用程式運行期間
        yield
    finally:
        # Shutdown 階段
        await close_resources()


app = FastAPI(lifespan=app_lifespan)

# 開發用
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(data_router, prefix="/data")