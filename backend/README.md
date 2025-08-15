```
# Activate virtual env
# - Before running FastAPI server (uvicorn)
# - Before installing new packages
# - Before running scripts or testing features in the backend
# PowerShell
.\venv-backend\Scripts\Activate.ps1
# Git Bash
source venv-backend/Scripts/activate

# Deactivate virtual env
# - when done working on the backend
deactivate

# Install dependencies
pip install -r requirements.txt

# Start server
uvicorn app.main:app --reload --port 8000

# Stop server
Ctrl + C

# Test Python code
python -m app.path.code

# To resume the Google Cloud Run hosting
# 1. Enable trigger at Cloud Build > Triggers > Select trigger > Enable
# 2. Allow url public access at Cloud Run > Select service > Security > Authentication > Allow public access > Save
```
