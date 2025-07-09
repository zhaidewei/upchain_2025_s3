#! /usr/bin/env python3
"""
https://decert.me/challenge/45779e03-7905-469e-822e-3ec3746d9ece
Quiz2:
Practice asymmetric encryption RSA (programming language not limited):

First generate a public-private key pair
Use the private key to sign "nickname + nonce" that has a hash value starting with 4 zeros (POW)
Verify with the public key
"""
import logging
import sys

from argparse import ArgumentParser

from utils import load_dotenv, get_or_create_key_pair, sign_message, verify_message


load_dotenv()
logging.basicConfig(level=logging.INFO, stream=sys.stderr)


def parse_args():
    "In case running alone"
    parser = ArgumentParser(description="RSA encrypt and decrypt")
    parser.add_argument("nickname_with_nonce", type=str, nargs='?',
                        help="The nickname+nonce string to sign. If not provided, reads from stdin.")
    return parser.parse_args()


def run():
    """
    Main function
    """
    load_dotenv()
    args = parse_args()
    # Get the nickname_with_nonce from args or stdin
    if args.nickname_with_nonce:
        nickname_with_nonce = args.nickname_with_nonce
        logging.info(f"Using argument: {nickname_with_nonce}")
    else:
        logging.info("Read from stdin")
        nickname_with_nonce = sys.stdin.read().strip()
        if not nickname_with_nonce:
            logging.error("No input received from stdin")
            sys.exit(1)
    private_key, public_key = get_or_create_key_pair()
    message = nickname_with_nonce
    signature = sign_message(private_key, message)
    logging.info(f"Signature (hex): {signature.hex()[:16]}...")
    logging.info(f"Message: {message}")

    is_valid = verify_message(public_key, message, signature)
    logging.info(f"Signature verified: {is_valid}")
    if is_valid:
        exit(0)
    else:
        exit(1)


if __name__ == "__main__":
    run()
