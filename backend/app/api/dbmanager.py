from datetime import datetime
from google.cloud import firestore
from io import BytesIO
from PIL import Image
from typing import Any, Dict, List, Optional
import base64
import json
import pandas as pd
import requests

from app.core.config import PASSWORD
from app.core.crypto import CryptoUtils
from app.core.firebase import db

class DbManager:
    def __init__(self, aiqueue):
        self.aiqueue = aiqueue
        self.pending_cases: Dict[str, Dict[str, Any]] = {}  # Data of cases that have already been sent to AIQueue

    def enqueue_ai_job(self, case_id: str, case_data: Dict[str, Any]):
        # 1. download encrypted blob from Firebase Storage
        # 2. decrypt blob using aes key
        # 3. extract 9 images from decrypted blob in order
        # 4. send case_id: [9 images] to AIQueue for AI diagnosis
        encrypted_aes = case_data.get("encrypted_aes", {})
        ciphertext = encrypted_aes.get("ciphertext")
        iv = encrypted_aes.get("iv")
        salt = encrypted_aes.get("salt")
        aes_key = CryptoUtils.decrypt_aes_key_with_passphrase(
            encrypted_aes_key_b64=ciphertext,
            passphrase=PASSWORD,
            salt_b64=salt,
            iv_b64=iv
        )

        encrypted_blob = case_data.get("encrypted_blob", {})
        url = encrypted_blob.get("url", "NULL")
        iv = encrypted_blob.get("iv", "NULL")
        if url == "NULL" or iv == "NULL":
            print(f"[DbManager] Invalid encrypted blob for case {case_id}. Cannot enqueue AI job.")
            return
        print(f"[DbManager] Downloading blob from URL: {url}")
        try:
            response = requests.get(url)
            if response.status_code != 200:
                raise RuntimeError(f"Failed to download blob: {response.status_code}")
            encrypted_blob = base64.b64encode(response.content).decode('utf-8')
        except Exception as e:
            print(f"[DbManager] Error downloading blob for case {case_id}: {e}")
            return
        
        print(f"[DbManager] Decrypting blob...")
        decrypted_data = CryptoUtils.decrypt_string(
            encrypted_blob,
            iv,
            aes_key
        )
        image_b64_list = json.loads(decrypted_data).get("images", [])
        if len(image_b64_list) != 9:
            print(f"[DbManager] Invalid number of images for case {case_id}. Cannot enqueue AI job.")
            return

        images = []
        for b64_str in image_b64_list:
            img_bytes = base64.b64decode(b64_str)
            img = Image.open(BytesIO(img_bytes)).convert("RGB")
            images.append(img)

        self.aiqueue.receive_new_case(case_id, images)
        print(f"[DbManager] Enqueued AI job for case: {case_id}")

    def receive_AI_results(self, results: Dict[str, Any]):
        new_cases = {}
        for case_id, predictions in results.items():
            if case_id not in self.pending_cases:
                print(f"[DbManager] Warning: Received AI result for unknown case_id: {case_id}")
                continue
            case_data = self.pending_cases[case_id]

            diagnoses = case_data.get("diagnoses", [])
            if len(diagnoses) != len(predictions):
                print(f"[DbManager] Mismatch between diagnosis count and predictions for case {case_id}")
                continue

            for i in range(len(diagnoses)):
                diagnoses[i]["ai_lesion_type"] = predictions[i]

            case_data["diagnoses"] = diagnoses
            new_cases[case_id] = case_data
            del self.pending_cases[case_id]
        
        self._batch_write_new_cases(new_cases)

    def _batch_write_new_cases(self, new_cases: Dict[str, Dict[str, Any]]):
        print(f"[DbManager] Batch writing {len(new_cases)} cases to Firestore...")
        try:
            batch = db.batch()
            for case_id, case_data in new_cases.items():
                case_data["submitted_at"] = firestore.SERVER_TIMESTAMP
                doc_ref = db.collection("cases").document(case_id)
                batch.set(doc_ref, case_data)
            batch.commit()
            print(f"[DbManager] Batch wrote {len(new_cases)} cases to Firestore.")
        except Exception as e:
            print(f"[DbManager] Error batch writing cases: {str(e)}")

    def get_case_by_id(self, case_id: str) -> Optional[Dict]:
        doc = db.collection("cases").document(case_id).get()
        if doc.exists:
            print(f"[DbManager] Retrieved case {case_id} from Firestore.")
            return doc.to_dict()
        print(f"[DbManager] Case {case_id} not found in Firestore.")
        return None

    def edit_case_by_id(self, case_id: str, updates: Dict[str, Any]):
        db.collection("cases").document(case_id).update(updates)
        print(f"[DbManager] Updated case {case_id}.")

    def get_undiagnosed_cases(self, clinician_id: str):
        print(f"[DbManager] Retrieving undiagnosed cases for clinician {clinician_id}...")

        cases = db.collection("cases").stream()
        undiagnosed_cases = []

        for doc in cases:
            case_data = doc.to_dict()
            diagnoses_list = case_data.get("diagnoses", [])

            if any(clinician_id not in diag for diag in diagnoses_list):
                undiagnosed_cases.append({
                "case_id": doc.id,
                **case_data
            })
                
        print(f"[DbManager] Found {len(undiagnosed_cases)} undiagnosed cases for clinician {clinician_id}.")
        return undiagnosed_cases

    def submit_case_diagnosis(self, case_id: str, diagnoses: List[Dict[str, Any]]):
        print(f"[DbManager] Submitting case diagnosis for case {case_id}...")
        doc_ref = db.collection("cases").document(case_id)
        doc_snapshot = doc_ref.get()

        if not doc_snapshot.exists:
            print(f"[DbManager] Case {case_id} not found")
            return False

        data = doc_snapshot.to_dict()
        existing_diagnoses = data.get("diagnoses", [])

        if len(existing_diagnoses) < len(diagnoses):
            existing_diagnoses.extend([{} for _ in range(len(diagnoses) - len(existing_diagnoses))])

        for idx, diag in enumerate(diagnoses):
            if not isinstance(diag, dict):
                continue

            for clinician_id, diag_data in diag.items():
                existing_diagnoses[idx][clinician_id] = {
                    "clinical_diagnosis": diag_data.get("clinical_diagnosis", ""),
                    "lesion_type": diag_data.get("lesion_type", ""),
                    "low_quality": diag_data.get("low_quality", False),
                    # "timestamp": firestore.SERVER_TIMESTAMP, # Commented because of exception
                }

        doc_ref.update({"diagnoses": existing_diagnoses})
        print(f"[DbManager] Updated {case_id} with {len(diagnoses)} diagnoses")

    def get_all_cases(self):
        print(f"[DbManager] Retrieving all cases...")
        docs = db.collection("cases").stream()
        all_cases = []
        for doc in docs:
            case = doc.to_dict()
            case["case_id"] = doc.id
            all_cases.append(case)
        print(f"[DbManager] Retrieved {len(all_cases)} cases from Firestore.")
        return all_cases

    def export_mastersheet(self):
        print(f"[DbManager] Exporting mastersheet...")
        cases = self.get_all_cases()
        timestamp = datetime.now().strftime("%Y%m%dT%H%M%S")

        def _process_case(case: dict) -> dict:
            biopsy_lesion_type = case.get("biopsy_lesion_type")
            coe_lesion_type = case.get("coe_lesion_type")
            biopsy_clinical_diagnosis = case.get("biopsy_clinical_diagnosis")
            coe_clinical_diagnosis = case.get("coe_clinical_diagnosis")

            biopsy_agree_with_coe = "NULL"

            if biopsy_lesion_type and biopsy_lesion_type != "NULL" and coe_lesion_type and coe_lesion_type != "NULL":
                biopsy_agree_with_coe = "YES" if biopsy_lesion_type == coe_lesion_type else "NO"
                if biopsy_clinical_diagnosis and biopsy_clinical_diagnosis != "NULL" and coe_clinical_diagnosis and coe_clinical_diagnosis != "NULL":
                    biopsy_agree_with_coe = (
                        "YES"
                        if (biopsy_lesion_type == coe_lesion_type and biopsy_clinical_diagnosis == coe_clinical_diagnosis)
                        else "NO"
                    )
            case["biopsy_agree_with_coe"] = biopsy_agree_with_coe
            return case

        rows = []
        clinician_mapping = {}
        clinician_counter = 0

        for case in cases:
            for diagnose in case.get("diagnoses", []):
                for key, val in diagnose.items():
                    if isinstance(val, dict) and all(k in val for k in ["lesion_type", "clinical_diagnosis", "low_quality"]):
                        uid = key
                        if uid not in clinician_mapping:
                            clinician_counter += 1
                            clinician_mapping[uid] = f"clinician{clinician_counter:02d}"
        print(f"[DbManager] Mapped {len(clinician_mapping)} clinicians.")

        for case in cases:
            base = {
                "case_id": case.get("case_id"),
                "created_at": case.get("created_at"),
                "created_by": case.get("created_by"),
                "submitted_at": case.get("submitted_at"),
                "alcohol": case.get("alcohol"),
                "alcohol_duration": case.get("alcohol_duration"),
                "betel_quid": case.get("betel_quid"),
                "betel_quid_duration": case.get("betel_quid_duration"),
                "smoking": case.get("smoking"),
                "smoking_duration": case.get("smoking_duration"),
                "oral_hygiene_products_used": case.get("oral_hygiene_products_used"),
                "oral_hygiene_product_type_used": case.get("oral_hygiene_product_type_used"),
                "sls_containing_toothpaste": case.get("sls_containing_toothpaste"),
                "sls_containing_toothpaste_used": case.get("sls_containing_toothpaste_used")
            }

            diagnoses = case.get("diagnoses", [])
            if not diagnoses:
                row = base.copy()
                for i in range(9):
                    row.update({
                        "image_index": i,
                        "ai_lesion_type": "NULL",
                        "biopsy_clinical_diagnosis": "NULL",
                        "biopsy_lesion_type": "NULL",
                        "coe_clinical_diagnosis": "NULL",
                        "coe_lesion_type": "NULL",
                        "biopsy_agree_with_coe": "NULL",
                    })
                    for clinician in clinician_mapping.values():
                        row[f"{clinician}_lesion_type"] = "NULL"
                        row[f"{clinician}_clinical_diagnosis"] = "NULL"
                        row[f"{clinician}_low_quality"] = "NULL"
                    rows.append(row)
            else:
                for i, diagnose in enumerate(diagnoses):
                    row = base.copy()
                    processed = _process_case(diagnose)
                    row.update({
                        "image_index": i,
                        "ai_lesion_type": processed.get("ai_lesion_type", "NULL"),
                        "biopsy_clinical_diagnosis": processed.get("biopsy_clinical_diagnosis", "NULL"),
                        "biopsy_lesion_type": processed.get("biopsy_lesion_type", "NULL"),
                        "coe_clinical_diagnosis": processed.get("coe_clinical_diagnosis", "NULL"),
                        "coe_lesion_type": processed.get("coe_lesion_type", "NULL"),
                        "biopsy_agree_with_coe": processed.get("biopsy_agree_with_coe", "NULL")
                    })
                    for uid, clinician in clinician_mapping.items():
                        if uid in diagnose:
                            cdata = diagnose[uid]
                            row[f"{clinician}_lesion_type"] = cdata.get("lesion_type", "NULL")
                            row[f"{clinician}_clinical_diagnosis"] = cdata.get("clinical_diagnosis", "NULL")
                            row[f"{clinician}_low_quality"] = cdata.get("low_quality", "NULL")
                        else:
                            row[f"{clinician}_lesion_type"] = "NULL"
                            row[f"{clinician}_clinical_diagnosis"] = "NULL"
                            row[f"{clinician}_low_quality"] = "NULL"
                    rows.append(row)

        mastersheet_df = pd.DataFrame(rows)
        print(f"[DbManager] Exported master sheet with {len(mastersheet_df)} rows and {len(mastersheet_df.columns)} columns to a Pandas df.")

        mapping_rows = [{"clinician": cname, "clinician_uid": uid} for uid, cname in clinician_mapping.items()]
        mapping_df = pd.DataFrame(mapping_rows)
        print(f"[DbManager] Exported clinician mappings with {len(mapping_df)} rows and {len(mapping_df.columns)} columns to a Pandas df.")

        for col in mastersheet_df.select_dtypes(include=["datetimetz"]).columns:
            mastersheet_df[col] = mastersheet_df[col].dt.tz_localize(None)

        buf = BytesIO()
        with pd.ExcelWriter(buf, engine="openpyxl") as writer:
            mastersheet_df.to_excel(writer, index=True, sheet_name="mastersheet")
            mapping_df.to_excel(writer, index=True, sheet_name="clinicians")
        print(f"[DbManager] Written master sheet and clinician mapping to Excel buffer.")
        buf.seek(0)
        return timestamp, buf