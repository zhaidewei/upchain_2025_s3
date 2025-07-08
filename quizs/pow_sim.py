#!/usr/bin/env python3
"""
https://decert.me/challenge/45779e03-7905-469e-822e-3ec3746d9ece
Quiz #1 (Proof of Work Practice)

Practice Proof of Work (POW) by writing a program (using any programming language) that performs the following:

Use your own nickname plus a nonce, and keep modifying the nonce to compute the SHA-256 hash repeatedly.

Continue this process until you find a hash that starts with 4 leading zeros. Once found, print the time taken, the input used to generate the hash, and the resulting hash value.

Then continue the process until you find a hash that starts with 5 leading zeros, and again print the time taken, the input used, and the resulting hash.

Submit your program via a link to your GitHub repository.
"""

# Make a hash function
import os
import sys
import hashlib
import time
import logging
from argparse import ArgumentParser
from utils import load_dotenv

logging.basicConfig(level=logging.INFO, stream=sys.stderr)

MAX_SEARCH_TIME = 600  # 10 minutes in seconds


def hash_function(input_text: str) -> str:
    "Simple sha 256 hash function"
    return hashlib.sha256(input_text.encode()).hexdigest()


# Make a loop for searching for a nonce.
def contains_leading_zeros(text: str, num_zeros: int) -> bool:
    """
    Check if the text starts with num_zeros leading zeros.
    """
    if num_zeros:
        return text.startswith('0' * num_zeros)
    else:
        return True


def parse_args():
    parser = ArgumentParser()
    parser.add_argument("-n", "--nickname", type=str, required=False, default=None)
    parser.add_argument("-z", "--num_zeros", type=int, required=False, default=None)
    return parser.parse_args()


class NonceNotFoundError(Exception):
    pass


def run():
    load_dotenv()
    # Make a loop for searching for a nonce.
    args = parse_args()
    nickname = args.nickname
    num_zeros = args.num_zeros
    if not nickname:
        nickname = os.getenv("NICK_NAME", "Noname")
    if not num_zeros:
        num_zeros = os.getenv("NUM_ZEROS", 4)

    start_time = time.time()
    nonce = 0

    has_alerted = list(range(MAX_SEARCH_TIME // 60))
    logging.info(f"Searching for {num_zeros} leading zeros for {nickname}...")
    count = 0
    while time.time() - start_time < MAX_SEARCH_TIME * 1000:
        hash_value = hash_function(f"{nickname}{nonce}")
        if contains_leading_zeros(hash_value, num_zeros):
            logging.info(f"Found a Hash value: {hash_value} for {nickname} with nonce {nonce}")
            logging.info(f"Time taken: {time.time() - start_time} seconds")
            logging.info(f"Count of searches: {count}")
            print(f"{nickname}{nonce}", file=sys.stdout, flush=True)
            exit(0)
        nonce += 1
        count += 1
        duration = time.time() - start_time
        if int(duration) % 60 == 0 and int(duration) // 60 in has_alerted:
            logging.info(f"Duration: {int(duration)} minutes")
            logging.info(f"Count of searches: {count}")
            has_alerted.remove(int(duration) // 60)
    raise NonceNotFoundError(f"Nonce not found after {MAX_SEARCH_TIME} seconds for {nickname} to have {num_zeros} leading zeros")


# Main
if __name__ == "__main__":
    run()
