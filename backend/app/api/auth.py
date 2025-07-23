from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel, EmailStr
from typing import Optional
from enum import Enum
from firebase_admin import auth, firestore
from app.core.firebase import firebase_app, db

router = APIRouter()

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

@router.post("/register")
def register_user(data: RegisterUser):
    try:
        # Create user in Firebase Authentication
        user = auth.create_user(
            email=data.email,
            password=data.password,
            display_name=data.full_name
        )
        # Store role as custom user claim
        auth.set_custom_user_claims(user.uid, {"role": data.role.value})
        # Create user document in Firestore
        user_data = {
            "created_at": firestore.SERVER_TIMESTAMP,
            "email": data.email,
            "name": data.full_name,
            "role": data.role.value
        }
        if data.role == UserRole.clinician:
            user_data["public_rsa"] = data.public_rsa
            user_data["private_rsa"] = data.private_rsa
        db.collection("users").document(user.uid).set(user_data)
        
        response_data = {
            "uid": user.uid,
            "email": data.email,
            "name": data.full_name,
            "role": data.role.value
        }
        if data.role == UserRole.clinician:
            response_data["public_rsa"] = data.public_rsa
            response_data["private_rsa"] = data.private_rsa
            response_data["access_grant_request"] = notify_dbmanager_new_clinician(user.uid, data.public_rsa)

        return response_data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

def notify_dbmanager_new_clinician(uid: str, public_rsa: str):
    # Placeholder for notifying the database manager about a new clinician
    return True

@router.get("/me")
def get_current_user(request: Request):
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    try:
        decoded = auth.verify_id_token(token)
        uid = decoded["uid"]
        role = decoded.get("role")
        email = decoded["email"]
        
        user_doc = db.collection("users").document(uid).get()
        user_data = user_doc.to_dict() if user_doc.exists else {}

        return {
            "uid": uid,
            "email": email,
            "role": role,
            "name": user_data.get("name"),
        }
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
# def verify_token(request: Request):
#     auth_header = request.headers.get("Authorization")
#     if not auth_header or not auth_header.startswith("Bearer "):
#         raise HTTPException(status_code=401, detail="Authorization header missing or invalid")
    
#     id_token = auth_header.split(" ")[1]
#     try:
#         decoded_token = auth.verify_id_token(id_token)
#         return decoded_token  # includes uid, email, customClaims etc.
#     except Exception:
#         raise HTTPException(status_code=401, detail="Invalid or expired token")

# # Before calling get_profile, first call the function verify_token and pass its return value as the argument user
# @router.get("/profile")
# def get_profile(user=Depends(verify_token)):
#     return {
#         "uid": user["uid"],
#         "email": user["email"],
#         "role": user.get("role", "unknown"),
#     }