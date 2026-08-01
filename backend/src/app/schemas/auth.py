from typing import Optional

from pydantic import BaseModel


class TokenData(BaseModel):
    sub: Optional[str] = None
    email: Optional[str] = None
