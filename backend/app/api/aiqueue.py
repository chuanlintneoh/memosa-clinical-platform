from io import BytesIO
from threading import Lock, Timer
from typing import Any, Dict
import base64
import requests

from app.core.config import AI_URL

class AIQueue:
    def __init__(self, dbmanager, flush_interval_seconds: int = 3600, flush_maximum_cases: int = 1):
        self.dbmanager = dbmanager
        self._new_cases: Dict[str, Dict[str, Any]] = {} # Cases waiting to be flushed
        self._flush_interval_seconds = flush_interval_seconds
        self._flush_maximum_cases = flush_maximum_cases
        self._lock = Lock()
        self._start_periodic_flush()

    def _start_periodic_flush(self):
        self._flush()
        t = Timer(self._flush_interval_seconds, self._start_periodic_flush)
        t.daemon = True
        t.start()
        print(f"[AIQueue] Periodic flush started every {self._flush_interval_seconds} seconds.")

    def receive_new_case(self, case_id: str, images):
        with self._lock:
            self._new_cases[case_id] = {"images": images}
        print(f"[AIQueue] Received new case: {case_id}. Total cases in queue: {len(self._new_cases)}")
        self._check_cases_amount()
    
    def _check_cases_amount(self):
        with self._lock:
            if len(self._new_cases) >= self._flush_maximum_cases:
                print(f"[AIQueue] Cache reached maximum cases ({self._flush_maximum_cases}).")
                Timer(0, self._flush).start()

    def _flush(self):
        with self._lock:
            if len(self._new_cases) == 0:
                print("[AIQueue] No new cases to flush.")
                return
            
            flush_data = dict(self._new_cases)
            self._new_cases.clear()
        
        print(f"[AIQueue] Flushing {len(flush_data)} new cases to AI for diagnosis...")

        all_images = []
        case_to_slice = {}
        for case_id, case_data in flush_data.items():
            start_idx = len(all_images)
            all_images.extend(case_data["images"])  # Adds 9 images
            case_to_slice[case_id] = (start_idx, start_idx + 9)

        image_payload = []
        for img in all_images:
            buffered = BytesIO()
            img.save(buffered, format="JPEG")
            image_b64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
            image_payload.append(image_b64)

        try:
            response = requests.post(
                url=f"{AI_URL}/inference/predict",
                json={"images": image_payload},
                timeout=60
            )
            response.raise_for_status()
            predictions = response.json()["predictions"]
        except Exception as e:
            print(f"[AIQueue] Error during inference: {e}")
            return
        
        results = {}
        for case_id, (start, end) in case_to_slice.items():
            case_preds = predictions[start:end]
            results[case_id] = case_preds

        self.dbmanager.receive_AI_results(results)