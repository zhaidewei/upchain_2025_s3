# upchain_2025_s3

Homeworks for upchain bootcamp

## Project Overview
This repository contains solutions and scripts for the Upchain Bootcamp, including Proof of Work (PoW) simulation, RSA encryption/signing, and related Python utilities.

## Proof of Work Simulation (Quiz 1)
The `quizs/pow.py` script demonstrates a simple proof-of-work algorithm. It searches for a nonce such that the SHA-256 hash of your nickname and the nonce starts with a specified number of leading zeros.

### Usage
You can run the script directly with:

```bash
python3 quizs/pow.py -n <nickname> -z <num_zeros>
```

For example, to search for a hash with 4 leading zeros for the nickname `deweizhai`:

```bash
python3 quizs/pow.py -n deweizhai -z 4
```

**Default behavior** (without `-z` flag): Runs both 4 and 5 leading zeros sequentially as per original quiz requirements:

```bash
python3 quizs/pow.py -n deweizhai
```

Or use the provided Makefile target:

```bash
make hw1
```

## RSA Encryption and Signing (Quiz 2)
The `quizs/encrypt_decrypt.py` script demonstrates RSA public-key cryptography. It can:
- Generate RSA key pairs
- Load existing keys from files
- Sign messages with a private key
- Verify signatures with a public key

### Usage
You can run the script directly with:

```bash
python3 quizs/encrypt_decrypt.py <message>
```

Or pipe input from the PoW script:

```bash
python3 quizs/pow.py -n deweizhai -z 4 | python3 quizs/encrypt_decrypt.py
```

Or use the provided Makefile targets:

```bash
make hw2    # General pipeline execution
make quiz2  # Specific Quiz 2 requirements (POW with 4 zeros + RSA signing)
```

### Environment Variables
The RSA script supports the following environment variables:
- `PRIVATE_KEY_FILE`: Path to the private key file (default: 'private_key.pem')
- `PUBLIC_KEY_FILE`: Path to the public key file (default: 'public_key.pem')
- `KEY_SIZE`: RSA key size in bits (default: 2048)
- `MAX_SEARCH_TIME`: Maximum time for POW search in seconds (default: 600)

## Quiz 2 Complete Workflow
The Quiz 2 implementation demonstrates the complete cryptographic workflow:

1. **Proof of Work**: Find a nonce such that `SHA-256(nickname + nonce)` starts with 4 leading zeros
2. **RSA Key Generation**: Generate or load RSA public-private key pair
3. **Digital Signing**: Sign the `nickname + nonce` string with the private key
4. **Signature Verification**: Verify the signature using the public key

### Running Quiz 2
```bash
# Complete Quiz 2 workflow
make quiz2

# Manual execution
python3 quizs/pow.py -n deweizhai -z 4 | python3 quizs/encrypt_decrypt.py
```

## Pipeline Execution
The two scripts can be chained together to:
1. Find a nonce that produces a hash with the required leading zeros
2. Sign the resulting "nickname+nonce" string with RSA
3. Verify the signature

This demonstrates a complete workflow from proof-of-work to cryptographic signing.

## Project Structure
```
quizs/
├── pow.py              # Proof of Work implementation
├── encrypt_decrypt.py  # RSA encryption/signing implementation
├── utils.py           # Shared utilities (key management, crypto functions)
└── __pycache__/       # Python cache files
```

## Code Quality
This project uses several tools to maintain code quality:

### Pre-commit Hooks
This project uses [pre-commit](https://pre-commit.com/) to enforce Python code linting with flake8 before each commit.

#### Setup
1. Install pre-commit if you haven't already:
   ```bash
   pip install pre-commit
   ```
2. Install the git hook scripts:
   ```bash
   pre-commit install
   ```
3. Now, every commit will automatically run flake8 to check code style and quality.

### Flake8 Configuration
A `.flake8` configuration file is included to customize linting rules:
- Line length limit is set to 120 characters
- E501 (line too long) errors are disabled
- Common directories are excluded from linting

## Dependencies
- `rsa`: For RSA cryptographic operations
- `python-dotenv`: For environment variable management
- `timeout-function-decorator`: For POW timeout functionality

Install dependencies:
```bash
pip install rsa python-dotenv timeout-function-decorator
```

## .gitignore
A `.gitignore` file is included to exclude Python bytecode, build artifacts, virtual environments, editor settings, and pre-commit cache/config files from version control.
