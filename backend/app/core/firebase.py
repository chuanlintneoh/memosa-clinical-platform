import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("secrets/firebase_admin_key.json")
firebase_app = firebase_admin.initialize_app(cred)
db = firestore.client()