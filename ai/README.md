```
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
```

Project Structure:

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
│   └── model.pt                # Pretrained PyTorch or ONNX model
├── requirements.txt            # Dependencies
├── Dockerfile                  # For Cloud Run or other hosting
└── README.md                   # Documentation
```
