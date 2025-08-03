```
# Activate virtual env
# - Before running FastAPI server (uvicorn)
# - Before installing new packages
# - Before running scripts or testing features in the backend
# PowerShell
.\venv\Scripts\Activate.ps1
# Git Bash
source venv/Scripts/activate

# Deactivate virtual env
# - when done working on the backend
deactivate

# Install dependencies
pip install -r requirements.txt

# Start server
uvicorn app.main:app --reload

# Stop server
Ctrl + C
```
