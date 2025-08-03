from Crypto.Cipher import AES, PKCS1_OAEP
from Crypto.PublicKey import RSA
from Crypto.Util.Padding import pad, unpad
from Crypto.Random import get_random_bytes
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Hash import SHA256
import base64
import json

class CryptoUtils:
    @staticmethod
    def decode_public_key_from_pem(public_pem: str) -> RSA.RsaKey:
        return RSA.import_key(public_pem)
    
    @staticmethod
    def decode_private_key_from_pem(private_pem: str) -> RSA.RsaKey:
        return RSA.import_key(private_pem)
    
    @staticmethod
    def decrypt_private_key(encrypted_pem: str, password: str) -> str:
        data = base64.b64decode(encrypted_pem)
        iv = data[:16]
        ciphertext = data[16:]
        salt = b"memosa-salt"
        key = PBKDF2(password.encode(), salt, dkLen=32, count=1000, hmac_hash_module=SHA256)
        cipher = AES.new(key, AES.MODE_CBC, iv)
        decrypted = cipher.decrypt(ciphertext)
        unpadded = unpad(decrypted, AES.block_size)
        return unpadded.decode("utf-8")
    
    @staticmethod
    def encrypt_aes_key(aes_key: bytes, public_key: RSA.RsaKey) -> str:
        cipher_rsa = PKCS1_OAEP.new(public_key)
        encrypted_key = cipher_rsa.encrypt(aes_key)
        return base64.b64encode(encrypted_key).decode()

    @staticmethod
    def decrypt_aes_key(encrypted_key: str, private_key: RSA.RsaKey) -> bytes:
        encrypted_bytes = base64.b64decode(encrypted_key)
        cipher_rsa = PKCS1_OAEP.new(private_key)
        return cipher_rsa.decrypt(encrypted_bytes)
    
    @staticmethod
    def encrypt_case_data(case_data: dict, aes_key: bytes) -> str:
        iv = get_random_bytes(16)
        cipher = AES.new(aes_key, AES.MODE_CBC, iv)
        padded = pad(json.dumps(case_data).encode(), AES.block_size)
        ciphertext = cipher.encrypt(padded)
        return base64.b64encode(iv + ciphertext).decode()
    
    @staticmethod
    def decrypt_case_data(encrypted_data: str, aes_key: bytes) -> dict:
        data = base64.b64decode(encrypted_data)
        iv = data[:16]
        ciphertext = data[16:]
        cipher = AES.new(aes_key, AES.MODE_CBC, iv)
        decrypted = unpad(cipher.decrypt(ciphertext), AES.block_size)
        return json.loads(decrypted.decode())