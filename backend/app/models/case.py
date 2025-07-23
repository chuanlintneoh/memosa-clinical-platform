from typing import Optional, List, Dict
from pydantic import BaseModel, HttpUrl
from datetime import date, datetime

# class Patient(BaseModel):
#     name: str
#     idtype: str
#     idnumber: str
#     dob: date
#     gender: str
#     ethnicity: str
#     phonenum: str
#     address: str
#     attending_hospital: Optional[str] = None
#     consent_form: Optional[str] = None
#     smoking: Optional[bool] = None
#     smoking_duration: Optional[str] = None
#     beted_quid: Optional[bool] = None
#     beted_quid_duration: Optional[str] = None
#     alcohol: Optional[bool] = None
#     alcohol_duration: Optional[str] = None
#     lesion_clinical_presentation: Optional[str] = None
#     chief_complaint: Optional[str] = None
#     presenting_complaint_history: Optional[str] = None
#     medication_history: Optional[str] = None
#     medical_history: Optional[str] = None
#     sls_containing_toothpaste: Optional[bool] = None
#     sls_containing_toothpaste_used: Optional[str] = None
#     oral_hygiene_products_used: Optional[str] = None
#     oral_hygiene_product_type_used: Optional[str] = None
#     additional_comments: Optional[str] = None

class ClinicianDiagnosis(BaseModel):
    # 1 per clinician
    clinical_diagnosis: str
    lesion_type: str
    low_quality: bool
    timestamp: datetime

class ImageDiagnoses(BaseModel):
    # 1 per image
    ai_diagnosed_lesion_type: Optional[str] = None
    biopsy_clinical_diagnosis: Optional[str] = None
    biopsy_lesion_type: Optional[str] = None
    biopsy_report: Optional[str] = None
    coe_clinical_diagnosis: Optional[str] = None
    coe_lesion_type: Optional[str] = None
    clinicians: Dict[str, ClinicianDiagnosis] = {}

class CasePrivate(BaseModel):
    # To be encrypted, 1 per case
    images: List[str]
    patient: str

class Case(BaseModel):
    created_at: datetime
    created_by: str
    encrypted_blob_url: HttpUrl
    encrypted_keys: Dict[str, str] = {}
    diagnoses: List[ImageDiagnoses] = []