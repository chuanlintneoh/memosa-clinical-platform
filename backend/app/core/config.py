import os

if os.getenv("K_SERVICE"):
    GOOGLE_CLOUD_RUN = True
else:
    GOOGLE_CLOUD_RUN = False
    from dotenv import load_dotenv
    load_dotenv()

PASSWORD = os.getenv("PASSWORD")
FIREBASE_BUCKET_NAME = os.getenv("FIREBASE_BUCKET_NAME")
# SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")
# SENDGRID_SENDER_EMAIL = os.getenv("SENDGRID_SENDER_EMAIL")

if GOOGLE_CLOUD_RUN:
    AI_URL = os.getenv("AI_URL")
else:
    AI_URL = "http://localhost:8001"