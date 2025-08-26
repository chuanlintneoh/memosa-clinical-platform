from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Util.Padding import unpad
import base64

class CryptoUtils:
    @staticmethod
    def decrypt_aes_key_with_passphrase(
        encrypted_aes_key_b64: str,
        passphrase: str,
        salt_b64: str,
        iv_b64: str
    ) -> bytes:
        encrypted_aes_key = base64.b64decode(encrypted_aes_key_b64)
        salt = base64.b64decode(salt_b64)
        iv = base64.b64decode(iv_b64)

        derived_key = CryptoUtils._derive_key(passphrase, salt, 32)

        cipher = AES.new(derived_key, AES.MODE_CBC, iv)
        aes_key = unpad(cipher.decrypt(encrypted_aes_key), AES.block_size)

        return aes_key

    @staticmethod
    def decrypt_string(
        encrypted_data_b64: str,
        iv_b64: str,
        aes_key: bytes
    ) -> str:
        encrypted_data = base64.b64decode(encrypted_data_b64)
        iv = base64.b64decode(iv_b64)

        cipher = AES.new(aes_key, AES.MODE_CBC, iv)
        plain_bytes = unpad(cipher.decrypt(encrypted_data), AES.block_size)

        return plain_bytes.decode('utf-8')

    @staticmethod
    def _derive_key(
        passphrase: str,
        salt: bytes,
        length: int
    ) -> bytes:
        return PBKDF2(
            passphrase.encode('utf-8'),
            salt,
            dkLen=length,
            count=100000,
            hmac_hash_module=SHA256
        )
    
# def main():
#     encrypted_aes = "LwBItzfkh8brwhUVweqdivhW3vLNzzQujXulKUCao01jiEDx1Pa2aNZvQYZudnp2"
#     passphrase = "nothingbeatsajet2holiday"
#     salt = "KXKacNsZce0XlxfFfmh/YA=="
#     iv_aes = "4cJu7xevpwuNi4cWAT+0bg=="
#     ciphertext = "jB1V0jCGV80LJZXILwTqH231vkixNISnvu0ZLbBjgvs="
#     iv_text = "8yiXRTpiexOxAvCBYtkb9w=="
#     aes = CryptoUtils.decrypt_aes_key_with_passphrase(
#         encrypted_aes, passphrase, salt, iv_aes
#     )
#     print("Decrypted AES Key (base64):", base64.b64encode(aes).decode())
#     print("AES key matches:", base64.b64encode(aes).decode() == "QfnDhbulNFrpPodSq8qCXNNmBLsdyBiOkvCEjJFDhls=")

#     decrypted_text = CryptoUtils.decrypt_string(
#         ciphertext, iv_text, aes
#     )
#     print("Decrypted String:", decrypted_text)
#     print("Decrypted String matches:", decrypted_text == "Hello, World! I am Chuan Lin")

# if __name__ == "__main__":
#     main()