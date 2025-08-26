from fastapi import APIRouter, HTTPException, Request
from firebase_admin import auth, firestore

from app.core.firebase import db
from app.models.user import RegisterUser

auth_router = APIRouter()

@auth_router.post("/register")
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
        db.collection("users").document(user.uid).set(user_data)
        
        response_data = {
            "uid": user.uid,
            "email": data.email,
            "name": data.full_name,
            "role": data.role.value
        }

        return response_data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@auth_router.get("/login")
def login_user(request: Request):
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    try:
        decoded = auth.verify_id_token(token)
        uid = decoded["uid"]
        role = decoded.get("role")
        email = decoded["email"]

        user_doc = db.collection("users").document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User document not found")
        user_data = user_doc.to_dict()
        name = user_data.get("name", "")

        response = {
            "uid": uid,
            "email": email,
            "role": role,
            "name": name,
        }
        return response
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))