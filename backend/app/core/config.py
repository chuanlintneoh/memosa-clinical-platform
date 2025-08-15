from dotenv import load_dotenv
import os

# Only load .env if running locally
if os.getenv("GOOGLE_CLOUD_RUN") != "1":
    load_dotenv()

PASSWORD = os.getenv("PASSWORD")