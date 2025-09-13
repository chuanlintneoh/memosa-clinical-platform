import base64
import httpx

class Storage:
    @staticmethod
    async def download(download_url: str) -> str:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(download_url)
                if response.status_code == 200:
                    return base64.b64encode(response.content).decode("utf-8")
                else:
                    raise Exception(f"Failed to download: {response.status_code}")
        except Exception as e:
            raise Exception(f"Failed to download: {e}")