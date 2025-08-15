import base64
from threading import Timer
from io import BytesIO
import json
from PIL import Image
from app.core.crypto import CryptoUtils
import requests
from typing import Any, Dict, Optional
from app.core.firebase import db
from app.core.config import PASSWORD
from google.cloud import firestore

class DbManager:
    def __init__(self, aiqueue, sync_interval_seconds: int = 600):
        self.aiqueue = aiqueue
        # self.new_cases: Dict[str, Dict[str, Any]] = {}
        self.pending_cases: Dict[str, Dict[str, Any]] = {}  # Data of cases that have already been sent to AIQueue
        self.sync_interval_seconds = sync_interval_seconds
        # self.flush_interval_seconds = flush_interval_seconds
        # self.flush_maximum_cases = flush_maximum_cases
        self._start_periodic_sync()
        # self._start_periodic_flush()

    def _start_periodic_sync(self):
        Timer(self.sync_interval_seconds, self._start_periodic_sync).start()
        print(f"[DbManager] Periodic sync started every {self.sync_interval_seconds} seconds.")

    # def _start_periodic_flush(self):
    #     self._flush()
    #     Timer(self.flush_interval_seconds, self._start_periodic_flush).start()
    #     print(f"[DbManager] Periodic flush started every {self.flush_interval_seconds} seconds.")

    # def _check_cases_amount(self):
    #     if len(self.new_cases) >= self.flush_maximum_cases:
    #         print(f"[DbManager] Cache reached maximum cases ({self.flush_maximum_cases}).")
    #         self._start_periodic_flush()

    def _enqueue_ai_job(self, case_id: str, case_data: Dict[str, Any]):
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
    
    # def _flush(self):
    #     if len(self.new_cases) == 0:
    #         print("[DbManager] No cases to flush.")
    #         return
        
    #     print(f"[DbManager] Flushing {len(self.new_cases)} cases to Firestore...")
    #     try:
    #         batch = db.batch()
    #         for case_id, case_data in self.new_cases.items():
    #             case_data["submitted_at"] = firestore.SERVER_TIMESTAMP
    #             doc_ref = db.collection("cases").document(case_id)
    #             batch.set(doc_ref, case_data)
    #         batch.commit()
    #         print(f"[DbManager] Flushed {len(self.new_cases)} cases to Firestore.")
    #         self.new_cases.clear()
    #         print(f"[DbManager] Cleared new cases cache after flush. {len(self.new_cases)} cases in cache.")
    #     except Exception as e:
    #         print(f"[DbManager] Error flushing cases: {str(e)}")

    def _get_case_by_id(self, case_id: str) -> Optional[Dict]:
        doc = db.collection("cases").document(case_id).get()
        if doc.exists:
            print(f"[DbManager] Retrieved case {case_id} from Firestore.")
            return doc.to_dict()
        print(f"[DbManager] Case {case_id} not found in Firestore.")
        return None

    def _edit_case_by_id(self, case_id: str, updates: Dict[str, Any]):
        db.collection("cases").document(case_id).update(updates)

    def _get_undiagnosed_images(self, clinician_id: str):
        print(f"[DbManager] Retrieving undiagnosed images for clinician {clinician_id}...")
        cases = db.collection("cases").where(f"diagnoses.{clinician_id}", "==", None).stream()
        return [doc.to_dict() for doc in cases]
    
    def _submit_image_diagnosis(self, case_id: str, image_index: int, clinician_id: str, lesion_type: str, clinical_diagnosis: str, low_quality: bool = False):
        print(f"[DbManager] Submitting image diagnosis for case {case_id}...")
        doc_ref = db.collection("cases").document(case_id)
        doc_snapshot = doc_ref.get()
        if not doc_snapshot.exists:
            print(f"[DbManager] Case {case_id} not found")
            return False
        
        data = doc_snapshot.to_dict()
        diagnoses = data.get("diagnoses", [])

        if not (0 <= image_index < len(diagnoses)):
            print(f"[DbManager] Image index {image_index} out of range")
            return False

        if clinician_id not in diagnoses[image_index]:
            diagnoses[image_index][clinician_id] = {}

        diagnoses[image_index][clinician_id].update({
            "lesion_type": lesion_type,
            "clinical_diagnosis": clinical_diagnosis,
            "low_quality": low_quality,
            "timestamp": firestore.SERVER_TIMESTAMP
        })

        doc_ref.update({"diagnoses": diagnoses})
        print(f"[DbManager] Updated diagnosis for case {case_id} image {image_index} clinician {clinician_id}")
        return True

    def _get_all_cases(self):
        print(f"[DbManager] Retrieving all cases...")
        docs = db.collection("cases").stream()
        all_cases = [doc.to_dict() for doc in docs]
        print(f"[DbManager] Retrieved {len(all_cases)} cases from Firestore.")
        return all_cases