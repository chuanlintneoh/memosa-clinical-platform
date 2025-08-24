```
# Create virtual env
python -m venv venv-ai

# Activate virtual env
# - Before running FastAPI server (uvicorn)
# - Before installing new packages
# - Before running scripts or testing features in the ai
# PowerShell
.\venv-ai\Scripts\Activate.ps1
# Git Bash
source venv-ai/Scripts/activate

# Deactivate virtual env
# - when done working on the ai
deactivate

# Install dependencies
pip install -r requirements.txt

# Start server
uvicorn app.main:app --reload --port 8001

# Stop server
Ctrl + C

# Test Python code
python -m app.path.code

# Upload / Update gitignored model to Google Cloud Run
1. gsutil cp models/model_file.pth gs://<BUCKET-NAME>/memosa_ai_models/model_file.pth
2. (One time setup) IAM & Admin > IAM > <PROJECT_NUMBER>-compute@developer.gserviceaccount.com > Edit principal > Add another role > Storage Object Viewer > Save
3. Update app.core.config file "MODEL" variable

# To resume the Google Cloud Run hosting
# 1. Enable trigger at Cloud Build > Triggers > Select trigger > Enable
# 2. Allow url public access at Cloud Run > Select service > Security > Authentication > Allow public access > Save
```

Project Structure for local development:

```
ai/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI entrypoint
│   ├── api/
│   │   ├── __init__.py
│   │   └── inference.py        # /predict endpoint logic
│   ├── core/
│   │   ├── __init__.py
│   │   ├── model.py            # Model loading and prediction
│   │   └── utils.py            # Preprocessing/postprocessing helpers
│   └── config.py               # Global config and env loading
├── models/
│   └── model.pth               # Pretrained PyTorch or ONNX model
├── requirements.txt            # Dependencies
├── Dockerfile                  # For Cloud Run or other hosting
└── README.md                   # Documentation
```

Project Structure for deployed Cloud Run container:

```
├── ai/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                 # FastAPI entrypoint
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   └── inference.py        # /predict endpoint logic
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── model.py            # Model loading and prediction
│   │   │   └── utils.py            # Preprocessing/postprocessing helpers
│   │   └── config.py               # Global config and env loading
│   ├── requirements.txt            # Dependencies
│   ├── Dockerfile                  # For Cloud Run or other hosting
│   └── README.md                   # Documentation
└── tmp/
    └── models/
        └── model.pth               # Pretrained PyTorch or ONNX model
```
