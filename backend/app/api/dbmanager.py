from app.models.case import ClinicianDiagnosis, ImageDiagnoses, CasePrivate, Case
from typing import Dict
from datetime import datetime

class DbManager:
    def __init__(self):
        self.cache = {}

    # def _encrypt_case(self, case: CasePrivate) -> str:
    #     encrypted_blob = None
    #     return encrypted_blob
    
    # def _upload_to_firebase_storage(self, encrypted_blob: str) -> str:
    #     encrypted_blob_url = None
    #     return encrypted_blob_url
    
    def _generate_encrypted_keys(self) -> Dict[str, str]:
        encrypted_keys = {}
        return encrypted_keys
    
    def _store_case_in_db(self, case: Case):
        pass

    # def create_case(self, case: CasePrivate, created_by: str) -> Case:
    #     encrypted_blob = self._encrypt_case(case)
    #     encrypted_blob_url = self._upload_to_firebase_storage(encrypted_blob)
    #     encrypted_keys = self._generate_encrypted_keys()
    #     new_case = Case(
    #         created_at=datetime.now(),
    #         created_by=created_by,
    #         encrypted_blob_url=encrypted_blob_url,
    #         encrypted_keys=encrypted_keys,
    #         diagnoses=[]
    #     )
    #     self._store_case_in_db(new_case)