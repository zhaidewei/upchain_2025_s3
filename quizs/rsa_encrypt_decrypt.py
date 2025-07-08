#! /usr/bin/env python3
"""
https://decert.me/challenge/45779e03-7905-469e-822e-3ec3746d9ece
Quiz2:
Practice asymmetric encryption RSA (programming language not limited):

First generate a public-private key pair
Use the private key to sign "nickname + nonce" that has a hash value starting with 4 zeros (POW)
Verify with the public key

# Solution Requirements
1. Allow reusing existing key pairs or genrating new key pairs.
2. Can be run independently or integrated in a pipeline (since quize 1)
3. Use dot env to get configurations
4. Can be chained via | with the first quiz pow_sim.py

Solution Design:
1. Accept a positional argument for the nickname + nonce, if not provided, read from the stdin
2. Try first use the enviroment variables to load the key pair, if not found, generate a new one
3. Print the signature (hex) and the message

"""
import logging
import os
import sys
import rsa
from typing import Tuple
from argparse import ArgumentParser

from utils import load_dotenv

logging.basicConfig(level=logging.INFO, stream=sys.stderr)  # in order to chain different scripts


def parse_args():
    "In case running alone"
    parser = ArgumentParser(description="RSA encrypt and decrypt")
    parser.add_argument("nickname_with_nonce", type=str, nargs='?',
                        help="The nickname+nonce string to sign. If not provided, reads from stdin.")
    return parser.parse_args()


def generate_key_pair(key_size: int = 2048) -> Tuple[rsa.PrivateKey, rsa.PublicKey]:
    """
    Generate a public-private key pair
    """
    return rsa.newkeys(key_size)


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
        public_key, private_key = generate_key_pair(key_size)
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


def run():
    """
    Main function
    """
    load_dotenv()
    args = parse_args()
    # Get the nickname_with_nonce from args or stdin
    if args.nickname_with_nonce:
        # If direct argument is provided, start immediately
        logging.info(f"\n{'#'* 20} Starting RSA encrypt and decrypt {'#'* 20}\n")
        nickname_with_nonce = args.nickname_with_nonce
        logging.info(f"Using argument: {nickname_with_nonce}")
    else:
        # For pipeline usage, wait for input before printing header
        nickname_with_nonce = sys.stdin.read().strip()
        if not nickname_with_nonce:
            logging.error("No input received from stdin")
            sys.exit(1)
        # Only print header after receiving input from pow_sim.py
        logging.info(f"\n{'#'* 20} Starting RSA encrypt and decrypt {'#'* 20}\n")
        logging.info(f"Read from stdin: {nickname_with_nonce}")

    # Try to load existing key files, otherwise generate new ones
    private_key, public_key = get_or_create_key_pair()

    # Test message
    message = nickname_with_nonce

    # Sign the message
    signature = sign_message(private_key, message)
    print(f"Signature (hex): {signature.hex()[:16]}...")
    print(f"Message: {message}")

    # Verify the signature
    is_valid = verify_message(public_key, message, signature)
    print(f"Signature verified: {is_valid}")


if __name__ == "__main__":
    run()
