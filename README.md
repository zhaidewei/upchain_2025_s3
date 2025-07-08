# upchain_2025_s3

Homeworks for upchain bootcamp

## Project Overview
This repository contains solutions and scripts for the Upchain Bootcamp, including Proof of Work (PoW) simulation and related Python utilities.

## Proof of Work Simulation
The `pow_sim.py` script demonstrates a simple proof-of-work algorithm. It searches for a nonce such that the SHA-256 hash of your nickname and the nonce starts with a specified number of leading zeros.

### Usage
You can run the script directly with:

```bash
python3 pow_sim.py -n <nickname> -z <num_zeros>
```

For example, to search for a hash with 7 leading zeros for the nickname `deweizhai`:

```bash
python3 pow_sim.py -n deweizhai -z 7
```

Or use the provided Makefile target:

```bash
make homework1
```

## Pre-commit Hooks
This project uses [pre-commit](https://pre-commit.com/) to enforce Python code linting with flake8 before each commit.

### Setup
1. Install pre-commit if you haven't already:
   ```bash
   pip install pre-commit
   ```
2. Install the git hook scripts:
   ```bash
   pre-commit install
   ```
3. Now, every commit will automatically run flake8 to check code style and quality.

## .gitignore
A `.gitignore` file is included to exclude Python bytecode, build artifacts, virtual environments, editor settings, and pre-commit cache/config files from version control.
