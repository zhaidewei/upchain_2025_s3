import os
from dotenv import load_dotenv as _load_dotenv


def load_dotenv():
    _load_dotenv()
    return os.environ
