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