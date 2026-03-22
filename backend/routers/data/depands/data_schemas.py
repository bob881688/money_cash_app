from pydantic import BaseModel

class CreateDataRequired(BaseModel):
    info: str
    stock_amount: int = 0
    balance: int

class UpdateDataRequired(BaseModel):
    info: str
    stock_amount: int = 0
    balance: int