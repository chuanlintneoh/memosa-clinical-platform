import os

if os.getenv("K_SERVICE"):
    GOOGLE_CLOUD_RUN = True
else:
    GOOGLE_CLOUD_RUN = False
    from dotenv import load_dotenv
    load_dotenv()

PASSWORD = os.getenv("PASSWORD")

if GOOGLE_CLOUD_RUN:
    AI_URL = os.getenv("AI_URL")
else:
    AI_URL = "http://localhost:8001"