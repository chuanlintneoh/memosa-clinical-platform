from enum import Enum
from pydantic import BaseModel, EmailStr
from typing import Optional

class UserRole(str, Enum):
    study_coordinator = "study_coordinator"
    clinician = "clinician"
    admin = "admin"

class RegisterUser(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: UserRole
    public_rsa: Optional[str] = None
    private_rsa: Optional[str] = None

class LoginUser(BaseModel):
    email: EmailStr
    password: str