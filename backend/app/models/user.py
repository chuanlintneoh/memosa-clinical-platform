from enum import Enum
from pydantic import BaseModel, EmailStr

class UserRole(str, Enum):
    study_coordinator = "study_coordinator"
    clinician = "clinician"
    admin = "admin"

class RegisterUser(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: UserRole
    invite_code: str  # Required invite code for registration

# class LoginUser(BaseModel):
#     email: EmailStr
#     password: str