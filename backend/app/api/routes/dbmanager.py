from dateutil import parser
from fastapi import APIRouter, BackgroundTasks, Query, Request
from fastapi.responses import JSONResponse
from typing import Any, Dict
from app.api.bootstrap import dbmanager

dbmanager_router = APIRouter()

@dbmanager_router.post("/case/create")
async def create_case(
    request: Request,
    background_tasks: BackgroundTasks,
    case_id: str = Query(...)
):
    try:
        # 1. receives case data
        data: Dict[str, Any] = await request.json()
        data["created_at"] = parser.isoparse(data["created_at"])

        # 2. check field existences
        encrypted_aes = data.get("encrypted_aes", {})
        if not encrypted_aes:
            return JSONResponse(content={"error": "Missing encrypted AES key"}, status_code=400)
        
        # 3. store case in cache
        dbmanager.pending_cases[case_id] = data
        # dbmanager._check_cases_amount()

        # 4. queue job for AI diagnosis
        background_tasks.add_task(dbmanager._enqueue_ai_job, case_id, data)

        return JSONResponse(content={"case_id": case_id}, status_code=200)

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@dbmanager_router.get("/case/{case_id}")
def get_case(case_id: str):
    return dbmanager._get_case_by_id(case_id)

# @dbmanager_router.post("/case/edit")
# def edit_case(request: Request, case_id: str = Query(...), updates: Dict[str, Any] = Query(...)):
#     return dbmanager._edit_case_by_id(case_id, updates)

# @dbmanager_router.get("/cases/undiagnosed/{clinician_id}")
# def get_undiagnosed_images(clinician_id: str):
#     return dbmanager._get_undiagnosed_images(clinician_id)

# @dbmanager_router.post("/case/diagnose")
# def diagnose_case(case_id: str, image_index: int, clinician_id: str, lesion_type: str, clinical_diagnosis: str, low_quality: bool = False):
#     return dbmanager._submit_image_diagnosis(case_id, image_index, clinician_id, lesion_type, clinical_diagnosis, low_quality)

# @dbmanager_router.get("/cases/all")
# def get_all_cases():
#     return dbmanager._get_all_cases()

# AIQueue flow:
# 1. AIQueue receives new cases from DbManager and adds them to the queue
# 2. AIQueue flush cases to AI diagnosis service for batch inference (time interval or max cases reached)
# 3. AIQueue wait with timeout for AI diagnosis service to return results
# 4. AIQueue append diagnosis results to case id (no results / exceed timeout = "FAILED") and send back to DbManager

# questions on this code:
# isnt it async? which and when should be async?

# the tasks of dbmanager include:
# - store newly created case
# - arrange new job to ai queue service for new case created
# - query for case using case id
# - edit existing case
# - query for list of undiagnosed cases for a clinician using clinician id
# - store diagnosis/diagnoses newly created by a clinician
# - query for list of all cases for admins