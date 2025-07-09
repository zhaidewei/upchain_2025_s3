import os
import logging
from typing import Tuple
import hashlib
import rsa

def hash_function(input_text: str) -> str:
    """Simple sha 256 hash function"""
    return hashlib.sha256(input_text.encode()).hexdigest()

def contains_leading_zeros(text: str, num_zeros: int) -> bool:
    """
    Check if the text starts with num_zeros leading zeros.
    """
    if num_zeros:
        return text.startswith('0' * num_zeros)
    else:
        return True


def sign_message(private_key: rsa.PrivateKey, message: str) -> bytes:
    """
    Sign a message with the private key
    """
    return rsa.sign(message.encode(), private_key, 'SHA-256')


def verify_message(public_key: rsa.PublicKey, message: str, signature: bytes) -> bool:
    """
    Verify a message with the public key
    """
    try:
        rsa.verify(message.encode(), signature, public_key)
        return True
    except rsa.VerificationError:
        return False


def get_or_create_key_pair() -> Tuple[rsa.PrivateKey, rsa.PublicKey]:
    """
    Get or create a key pair
    """
    private_key_file = os.getenv("PRIVATE_KEY_FILE", 'private_key.pem')
    public_key_file = os.getenv("PUBLIC_KEY_FILE", 'public_key.pem')
    key_size = int(os.getenv("KEY_SIZE", "2048"))

    # Try to load existing keys (support both PKCS#1 and OpenSSH formats)
    try:
        logging.info(f"Attempting to load keys from {private_key_file}")
        with open(private_key_file, "rb") as f:
            key_content = f.read()

        # Try to load as PKCS#1 format
        private_key = rsa.PrivateKey.load_pkcs1(key_content)
        public_key = rsa.PublicKey(private_key.n, private_key.e)

        logging.info("Successfully loaded existing key pair")

    except Exception as e:
        logging.warning(f"Could not load existing keys: {e}")
        logging.info("Generating new RSA key pair...")
        public_key, private_key = rsa.newkeys(key_size)
        # Then create it
        # Only create directories if there's a directory path
        if os.path.dirname(private_key_file):
            os.makedirs(os.path.dirname(private_key_file), exist_ok=True)
        with open(private_key_file, "wb") as f:
            f.write(private_key.save_pkcs1())
        logging.info(f"Saved private key to {private_key_file}")

        if os.path.dirname(public_key_file):
            os.makedirs(os.path.dirname(public_key_file), exist_ok=True)
        with open(public_key_file, "wb") as f:
            f.write(public_key.save_pkcs1())
        logging.info(f"Saved public key to {public_key_file}")
    return private_key, public_key
