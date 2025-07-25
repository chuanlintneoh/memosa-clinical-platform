from fastapi import APIRouter, HTTPException, Request
from firebase_admin import auth, firestore
from app.core.firebase import firebase_app, db
from app.models.user import UserRole, RegisterUser

router = APIRouter()

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

@router.get("/login")
def login_user(request: Request):
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    try:
        decoded = auth.verify_id_token(token)
        uid = decoded["uid"]
        role = decoded.get("role")
        email = decoded["email"]

        if role in ["admin", "study_coordinator"]:
            doc_ref = db.collection("users").document("shared-key")
        elif role == "clinician":
            doc_ref = db.collection("users").document(uid)
        else:
            raise HTTPException(status_code=403, detail="Unknown role")
        
        doc = doc_ref.get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="User document not found")
        
        user_data = doc.to_dict()

        return {
            "uid": uid,
            "email": email,
            "role": role,
            "name": user_data.get("name"),
            "public_rsa": user_data.get("public_rsa"),
            "private_rsa": user_data.get("private_rsa"),
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

# development use only
@router.post("/store-key")
async def store_key(request: Request):
    data = await request.json()
    public_rsa = data.get("public_rsa")
    private_rsa = data.get("private_rsa")
    try:
        db.collection("users").document("shared-key").update({
            "public_rsa": public_rsa,
            "private_rsa": private_rsa,
        })
        return {"message": "Keys stored successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))