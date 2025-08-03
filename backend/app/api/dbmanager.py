from threading import Timer
from fastapi import APIRouter, Query, Request
from fastapi.responses import JSONResponse
from app.core.crypto import CryptoUtils
# from app.models.case import ClinicianDiagnosis, ImageDiagnoses, CasePrivate, Case
from typing import Any, Dict, Optional
from app.core.firebase import db
from app.core.config import PASSWORD, SYSTEM_PUBLIC_RSA, ENCRYPTED_SYSTEM_PRIVATE_RSA, SHARED_PUBLIC_RSA
from google.cloud import firestore
from dateutil import parser
# import datetime

router = APIRouter()

class DbManager:
    def __init__(self, sync_interval_seconds: int = 600, flush_interval_seconds: int = 3600, flush_maximum_cases: int = 1):
        self.public_rsa_keys: Dict[str, Any] = {}
        self.new_cases: Dict[str, Dict[str, Any]] = {}
        self.public_rsa_keys = {
            "system": SYSTEM_PUBLIC_RSA,
            "shared": SHARED_PUBLIC_RSA
        } # remember to decode from PEM format before using
        if not SYSTEM_PUBLIC_RSA or not SHARED_PUBLIC_RSA:
            self._get_shared_system_rsa_keys()
        self.sync_interval_seconds = sync_interval_seconds
        self.flush_interval_seconds = flush_interval_seconds
        self.flush_maximum_cases = flush_maximum_cases
        self._start_periodic_sync()
        self._start_periodic_flush()

    def _get_shared_system_rsa_keys(self):
        updated_keys = {}
        shared_doc = db.collection("users").document("shared-key").get()
        if shared_doc.exists and "public_rsa" in shared_doc.to_dict():
            updated_keys["shared"] = shared_doc.to_dict()["public_rsa"]

        system_doc = db.collection("users").document("system-key").get()
        if system_doc.exists and "public_rsa" in system_doc.to_dict():
            updated_keys["system"] = system_doc.to_dict()["public_rsa"]

        self.public_rsa_keys = updated_keys
        print(f"[DbManager] Retrieved shared and system public RSA keys. {len(self.public_rsa_keys)} public RSA keys in cache.")

    def _start_periodic_sync(self):
        self._sync_clinicians_rsa_keys()
        Timer(self.sync_interval_seconds, self._start_periodic_sync).start()
        print(f"[DbManager] Periodic sync started every {self.sync_interval_seconds} seconds.")

    def _start_periodic_flush(self):
        self._flush()
        Timer(self.flush_interval_seconds, self._start_periodic_flush).start()
        print(f"[DbManager] Periodic flush started every {self.flush_interval_seconds} seconds.")

    def _check_cases_amount(self):
        if len(self.new_cases) >= self.flush_maximum_cases:
            print(f"[DbManager] Cache reached maximum cases ({self.flush_maximum_cases}). Flushing to Firestore...")
            self._start_periodic_flush()
    
    def _sync_clinicians_rsa_keys(self):
        clinicians_ref = db.collection("users").where("role", "==", "clinician")
        clinicians_list = list(clinicians_ref.stream())
        print(f"[DbManager] Synchronizing {len(clinicians_list)} clinician public RSA keys from Firestore...")
        for doc in clinicians_list:
            data = doc.to_dict()
            uid = doc.id
            if "public_rsa" in data:
                self.public_rsa_keys[uid] = data["public_rsa"]
        print(f"[DbManager] Synchronized clinician public RSA keys. {len(self.public_rsa_keys)} public RSA keys in cache.")

    def add_new_clinician_key(self, uid: str, public_rsa: str):
        self.public_rsa_keys[uid] = public_rsa
        print(f"[DbManager] Added new clinician public RSA key for UID: {uid}. {len(self.public_rsa_keys)} public RSA keys in cache.")
        return True

    def generate_encrypted_keys_for_new_clinician(self, uid: str, public_rsa: str):
        # generate encrypted keys for the new clinician
        # 1. retrieve all cases
        # 2. decrypt all aes keys using system private rsa key
        # 3. encrypt all aes keys using new clinician public rsa key
        # 4. write to firestore
        # very heavy operation, potentially need improvement on optimization
        # potential strategy: Only generate and write the encrypted AES key for the new clinician when they first access or are assigned a case - Source (FYP(25))
        print(f"[DbManager] Generating encrypted keys for new clinician {uid}...")
        try:
            batch = db.batch()
            public_key = CryptoUtils.decode_public_key_from_pem(public_rsa)
            system_private_key = CryptoUtils.decode_private_key_from_pem(CryptoUtils.decrypt_private_key(ENCRYPTED_SYSTEM_PRIVATE_RSA, PASSWORD))
            cases = db.collection("cases").stream()
            final_count = 0
            count = 0
            for case_doc in cases:
                case_data = case_doc.to_dict()
                encrypted_system_key = case_data.get("encrypted_keys", {}).get("system")
                if not encrypted_system_key:
                    continue

                aes_key = CryptoUtils.decrypt_aes_key(encrypted_system_key, system_private_key)
                encrypted_key = CryptoUtils.encrypt_aes_key(aes_key, public_key)
                doc_ref = db.collection("cases").document(case_doc.id)
                batch.update(doc_ref, {f"encrypted_keys.{uid}": encrypted_key})
                final_count += 1
                count += 1

                if count == 500:
                    batch.commit()
                    batch = db.batch()
                    count = 0

            if count > 0:
                batch.commit()
            print(f"[DbManager] Generated encrypted keys for new clinician {uid}. {final_count} cases updated.")
            return True
        except Exception as e:
            print(f"[DbManager] Error generating encrypted keys for new clinician {uid}: {e}")
            return False

    def _enqueue_ai_job(self, case_id: str):
        # Replace with actual queueing logic, e.g., Firestore trigger or Cloud Task
        print(f"Enqueued AI job for case: {case_id}")
    
    def _flush(self):
        if len(self.new_cases) == 0:
            print("[DbManager] No cases to flush.")
            return
        
        print(f"[DbManager] Flushing {len(self.new_cases)} cases to Firestore...")
        try:
            batch = db.batch()
            for case_id, case_data in self.new_cases.items():
                case_data["submitted_at"] = firestore.SERVER_TIMESTAMP
                doc_ref = db.collection("cases").document(case_id)
                batch.set(doc_ref, case_data)
            batch.commit()
            print(f"[DbManager] Flushed {len(self.new_cases)} cases to Firestore.")
            self.new_cases.clear()
            print(f"[DbManager] Cleared new cases cache after flush. {len(self.new_cases)} cases in cache.")
        except Exception as e:
            print(f"[DbManager] Error flushing cases: {str(e)}")

    def _get_case_by_id(self, case_id: str) -> Optional[Dict]:
        doc = db.collection("cases").document(case_id).get()
        if doc.exists:
            return doc.to_dict()
        return None

    def _get_undiagnosed_cases(self, clinician_id: str):
        cases = db.collection("cases").where(f"diagnoses.{clinician_id}", "==", None).stream()
        return [doc.to_dict() for doc in cases]

    def _get_all_cases(self):
        docs = db.collection("cases").stream()
        return [doc.to_dict() for doc in docs]

    def _submit_diagnoses(self, case_id: str, diagnoses: Dict[str, Dict]):
        db.collection("cases").document(case_id).update({f"diagnoses": diagnoses})

dbmanager = DbManager()

@router.post("/case/create")
async def create_case(request: Request, case_id: str = Query(...)):
    try:
        # 1. receives case data
        data: Dict[str, Any] = await request.json()
        data["created_at"] = parser.isoparse(data["created_at"])

        # 2. decrypt aes key using system private rsa and encrypt it with all public rsa keys (_generate_encrypted_keys_for_new_case)
        encrypted_aes = data.get("encrypted_keys", {}).get("system")
        if not encrypted_aes:
            return JSONResponse(content={"error": "Missing system encrypted AES key"}, status_code=400)
        
        # 3. encrypt aes key with all public rsa keys
        private_key = CryptoUtils.decode_private_key_from_pem(CryptoUtils.decrypt_private_key(ENCRYPTED_SYSTEM_PRIVATE_RSA, PASSWORD))
        aes_key = CryptoUtils.decrypt_aes_key(encrypted_aes, private_key)
        for uid, public_rsa in dbmanager.public_rsa_keys.items():
            if uid != "system":
                encrypted_key = CryptoUtils.encrypt_aes_key(aes_key, CryptoUtils.decode_public_key_from_pem(public_rsa))
                # 4. append encrypted keys to case data
                data["encrypted_keys"][uid] = encrypted_key
        
        # 5. store case in cache
        dbmanager.new_cases[case_id] = data
        dbmanager._check_cases_amount()

        # 6. queue job for AI diagnosis (_enqueue_ai_job)
        dbmanager._enqueue_ai_job(case_id)

        return JSONResponse(content={"case_id": case_id}, status_code=200)

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

# @router.get("/case/{case_id}")
# def get_case(case_id: str):
#     pass

# @router.post("/case/edit")
# def edit_case(case_id: str, case: Case):
#     pass

# @router.get("/cases/undiagnosed/{clinician_id}")
# def get_undiagnosed_cases(clinician_id: str):
#     pass

# @router.post("/case/diagnose")
# def diagnose_case(case_id: str, diagnoses: ImageDiagnoses):
#     pass

# @router.get("/cases/all")
# def get_all_cases():
#     pass

# questions on this code:
# isnt it async? which and when should be async?

# the tasks of dbmanager include:
# - generate encrypted keys per existing case for new user
# - generate encrypted keys per key pair (clinician + shared key) for new case
# - store newly created case
# - arrange new job to ai queue service for new case created
# - query for case using case id
# - edit existing case
# - query for list of undiagnosed cases for a clinician using clinician id
# - store diagnosis/diagnoses newly created by a clinician
# - query for list of all cases for admins