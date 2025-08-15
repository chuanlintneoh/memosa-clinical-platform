from fastapi import FastAPI, Request
from app.api import inference

app = FastAPI()

app.include_router(inference.router, prefix="/inference")

@app.get("/")
def read_root(request: Request):
    docs_url = str(request.base_url) + "docs"
    return {"message": "FastAPI AI inferencing server is live! Go to $docs_url for API documentation.", "docs_url": docs_url}