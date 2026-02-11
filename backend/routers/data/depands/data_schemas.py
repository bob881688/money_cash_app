from pydantic import BaseModel

class CreateDataRequired(BaseModel):
    user_id: int
    info: str
    stock_amount: int = 0
    balance: int

class UpdateDataRequired(BaseModel):
    info: str
    stock_amount: int = 0
    balance: int