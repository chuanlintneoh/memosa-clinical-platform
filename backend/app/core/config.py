from dotenv import load_dotenv
import os

load_dotenv()

PASSWORD = os.getenv("PASSWORD")
SYSTEM_PUBLIC_RSA = os.getenv("SYSTEM_PUBLIC_RSA")
ENCRYPTED_SYSTEM_PRIVATE_RSA = os.getenv("ENCRYPTED_SYSTEM_PRIVATE_RSA")
SHARED_PUBLIC_RSA = os.getenv("SHARED_PUBLIC_RSA")