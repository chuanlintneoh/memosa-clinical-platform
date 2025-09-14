from dateutil import parser
from fastapi import APIRouter, BackgroundTasks, Query, Request
from fastapi.responses import JSONResponse, StreamingResponse
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

        # 4. queue job for AI diagnosis
        background_tasks.add_task(dbmanager.enqueue_ai_job, case_id, data)

        return JSONResponse(content={"case_id": case_id}, status_code=200)

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@dbmanager_router.get("/case/get/{case_id}")
def get_case(case_id: str):
    return dbmanager.get_case_by_id(case_id)

@dbmanager_router.post("/case/edit")
async def edit_case(
    request: Request,
    background_tasks: BackgroundTasks,
    case_id: str = Query(...)
):
    updates = await request.json()
    background_tasks.add_task(dbmanager.edit_case_by_id, case_id, updates)
    return JSONResponse(content={"case_id": case_id}, status_code=200)

@dbmanager_router.get("/cases/undiagnosed/{clinician_id}")
def get_undiagnosed_cases(clinician_id: str):
    return dbmanager.get_undiagnosed_cases(clinician_id)

@dbmanager_router.post("/case/diagnose")
async def diagnose_case(
    request:Request,
    background_tasks: BackgroundTasks,
    case_id: str = Query(...)
):
    body = await request.json()
    diagnoses = body.get("diagnoses", [])

    background_tasks.add_task(dbmanager.submit_case_diagnosis, case_id, diagnoses)
    return JSONResponse(content={"case_id": case_id}, status_code=200)

@dbmanager_router.get("/cases/all")
def get_all_cases():
    return dbmanager.get_all_cases()

@dbmanager_router.get("/cases/export")
async def export_mastersheet(include_all: bool = False):
    buf, timestamp = await dbmanager.export_bundle(include_all=include_all)
    return StreamingResponse(
        buf,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename=mastersheet_{timestamp}.xlsx"}
    )

@dbmanager_router.get("/bundle/export")
async def export_bundle(include_all: bool = False, expiry_days: int = 1):
    try:
        url, password, timestamp = await dbmanager.export_bundle(include_all=include_all, signed_url=True, expiry_seconds=expiry_days * 24 * 3600)
        if not url:
            return {
                "status": "failed",
                "error": "No url returned"
            }
        return {
            "status": "success",
            "url": url,
            "password": password,
            "timestamp": timestamp,
            "expiry_days": expiry_days,
            "include_all": include_all,
        }
    except Exception as e:
        print(f"[DbManager] Failed to generate/download bundle: {e}")
        return {
            "status": "failed",
            "error": str(e)
        }

# @dbmanager_router.get("/bundle/email")
# async def email_bundle(email: str, include_all: bool = False):
#     try:
#         password = await dbmanager.export_bundle(include_all=include_all, email=email)
#         return {
#             "status": "success" if password != "NULL" else "failed",
#             "password": password if password != "NULL" else None,
#             "email": email,
#             "include_all": include_all,
#         }
#     except Exception as e:
#         print(f"[DbManager] Failed to generate/email bundle: {e}")
#         return {
#             "status": f"failed: {e}",
#             "email": email,
#             "include_all": include_all,
#         }
    
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