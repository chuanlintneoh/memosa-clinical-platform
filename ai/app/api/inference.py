import base64
from fastapi import APIRouter, HTTPException, Request
from io import BytesIO
import os
from PIL import Image
from torch.utils.data import DataLoader

from app.core import model
from app.core.config import MODEL, MODEL_PATH
from app.core.dataloader import InferenceDataset

router = APIRouter()

model = model.EfficientNetModel.load_from_checkpoint(f"{MODEL_PATH}/{MODEL}")

@router.post("/predict")
async def predict(request: Request):
    try:
        body = await request.json()
        image_b64_list = body.get("images", [])
        if not image_b64_list or not isinstance(image_b64_list, list):
            raise ValueError("Missing or invalid 'images' list in request.")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid JSON body: {e}")
    
    images = []
    for b64_str in image_b64_list:
        try:
            img_bytes = base64.b64decode(b64_str)
            img = Image.open(BytesIO(img_bytes)).convert("RGB")
            images.append(img)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Image decoding failed: {e}")
    
    dataset = InferenceDataset(images, transform=model.preprocess)
    dataloader = DataLoader(dataset, batch_size=9, shuffle=False)
    predictions = model.predict_batch(dataloader=dataloader)

    return {"predictions": predictions}