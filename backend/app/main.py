import os
import uvicorn
from fastapi import FastAPI, Request
from app.api import auth, dbmanager, aiqueue

app = FastAPI()

app.include_router(auth.router, prefix="/auth")
app.include_router(dbmanager.router, prefix="/dbmanager")
app.include_router(aiqueue.router, prefix="/aiqueue")

@app.get("/")
def read_root(request: Request):
    docs_url = str(request.base_url) + "docs"
    return {"message": "FastAPI backend is live! Go to $docs_url for API documentation.", "docs_url": docs_url}

if __name__ == "__main__":
    # For debugging: print the full runtime file structure
    import subprocess
    print("=== FULL RUNTIME FILE STRUCTURE ===")
    try:
        result = subprocess.run(["find", "/"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        print(result.stdout)
    except Exception as e:
        print("Error running find:", e)

    port = int(os.getenv("PORT", 8080))  # Cloud Run sets PORT; fallback to 8080
    uvicorn.run("app.main:app", host="0.0.0.0", port=port)