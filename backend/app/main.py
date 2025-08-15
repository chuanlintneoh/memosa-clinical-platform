# For debugging: print the full runtime file structure
# import subprocess
# print("=== FULL RUNTIME FILE STRUCTURE ===")
# try:
#     result = subprocess.run(["find", "/"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
#     print(result.stdout)
# except Exception as e:
#     print("Error running find:", e)

from fastapi import FastAPI, Request
from app.api.routes.auth import auth_router
from app.api.routes.dbmanager import dbmanager_router
from app.api.routes.aiqueue import aiqueue_router

app = FastAPI()

app.include_router(auth_router, prefix="/auth")
app.include_router(dbmanager_router, prefix="/dbmanager")
app.include_router(aiqueue_router, prefix="/aiqueue")

@app.get("/")
def read_root(request: Request):
    docs_url = str(request.base_url) + "docs"
    return {"message": "FastAPI backend is live! Go to $docs_url for API documentation.", "docs_url": docs_url}