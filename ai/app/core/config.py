from google.cloud import storage
import os

if os.getenv("K_SERVICE"):
    GOOGLE_CLOUD_RUN = True
else:
    GOOGLE_CLOUD_RUN = False
    from dotenv import load_dotenv
    load_dotenv()

MODEL = "CancerVOPMDVAll_effnetb2_ep30_lr1e-04_wd1e-03_20250801T011129_bp.pth"
GOOGLE_CLOUD_PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT")

if GOOGLE_CLOUD_RUN:
    MODEL_PATH = "/tmp/models" # absolute path
    try:
        os.makedirs(MODEL_PATH, exist_ok=True)
        storage.Client().bucket(f"{GOOGLE_CLOUD_PROJECT}.firebasestorage.app").blob(f"memosa_ai_models/{MODEL}").download_to_filename(f"{MODEL_PATH}/{MODEL}")
    except Exception as e:
        raise Exception(f"Error downloading model: {e}")
else:
    MODEL_PATH = "models" # relative path
