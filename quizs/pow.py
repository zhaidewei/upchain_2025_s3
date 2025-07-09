#!/usr/bin/env python3
"""
https://decert.me/challenge/45779e03-7905-469e-822e-3ec3746d9ece
Quiz #1 (Proof of Work Practice)

Practice Proof of Work (POW) by writing a program (using any programming language) that performs the following:

Use your own nickname plus a nonce, and keep modifying the nonce to compute the SHA-256 hash repeatedly.
Continue this process until you find a hash that starts with 4 leading zeros.
Once found, print the time taken, the input used to generate the hash, and the resulting hash value.
Then continue the process until you find a hash that starts with 5 leading zeros, and again print the time taken, the input used, and the resulting hash.

Submit your program via a link to your GitHub repository.
"""
import os
import sys
import hashlib
import time
import logging
from argparse import ArgumentParser
from timeout_function_decorator import timeout
from utils import load_dotenv, contains_leading_zeros


load_dotenv()
logging.basicConfig(level=logging.INFO, stream=sys.stderr)

MAX_SEARCH_TIME = int(os.getenv("MAX_SEARCH_TIME", 600))  # 10 minutes in seconds


def hash_function(input_text: str) -> str:
    """Simple sha 256 hash function"""
    return hashlib.sha256(input_text.encode()).hexdigest()


def parse_args():
    """In case running alone"""
    parser = ArgumentParser()
    parser.add_argument("-n", "--nickname", type=str, required=False, default='dewei')
    parser.add_argument("-z", "--num_zeros", type=int, required=False, default=4)
    return parser.parse_args()


@timeout(MAX_SEARCH_TIME)
def run(nickname: str, num_zeros: int):
    """Perform the POW for the given nickname and number of zeros"""
    logging.info(f"Searching nonce for {nickname} with {num_zeros} leading hash zeros ...")
    start_time = time.time()
    nonce = 0
    while True:
        hash_value = hash_function(f"{nickname}{nonce}")
        if contains_leading_zeros(hash_value, num_zeros):
            logging.info(f"Time taken: {time.time() - start_time:.4f} seconds")
            logging.info(f"Found nonce: {nonce}")
            logging.info(f"Hash value: {hash_value}")
            print(f"{nickname}{nonce}", file=sys.stdout, flush=True)  # so we can pipe it to the next script
            return
        nonce += 1


if __name__ == "__main__":
    args = parse_args()
    if args.num_zeros:
        # Single run mode (for pipeline)
        run(args.nickname, args.num_zeros)
    else:
        # Original quiz mode (both 4 and 5 zeros)
        run(args.nickname, 4)
        run(args.nickname, 5)
