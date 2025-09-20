from fastapi import HTTPException, Request
from firebase_admin import auth

def verify_token(request: Request):
    try:
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        decoded = auth.verify_id_token(token)
        uid = decoded["uid"]
        role = decoded.get("role")
        email = decoded["email"]

        return uid, role, email, decoded
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid or expired token") from e