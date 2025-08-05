import os
import firebase_admin
from firebase_admin import credentials, firestore

firebase_path = (
    "/secrets/firebase_admin_key.json"
    if os.path.exists("/secrets/firebase_admin_key.json")
    else "secrets/firebase_admin_key.json"
)
cred = credentials.Certificate(firebase_path)
firebase_app = firebase_admin.initialize_app(cred)
db = firestore.client()