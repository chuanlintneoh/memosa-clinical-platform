from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr
from app.models.user import UserRole


class InviteCodeCreate(BaseModel):
    """Request model for creating an invite code"""
    restricted_email: Optional[EmailStr] = None  # If set, only this email can use the code
    restricted_role: Optional[UserRole] = None   # If set, code can only be used for this role
    max_uses: int = 1                            # How many times the code can be used (0 = unlimited)
    expires_in_days: int = 30                    # Days until code expires


class InviteCodeValidate(BaseModel):
    """Request model for validating an invite code"""
    code: str
    email: EmailStr
    role: UserRole


class InviteCodeResponse(BaseModel):
    """Response model for invite code"""
    code: str
    created_at: datetime
    created_by: str
    expires_at: datetime
    restricted_email: Optional[str] = None
    restricted_role: Optional[str] = None
    max_uses: int
    times_used: int
    is_active: bool
    is_expired: bool


class InviteCodeRevoke(BaseModel):
    """Request model for revoking an invite code"""
    code: str
