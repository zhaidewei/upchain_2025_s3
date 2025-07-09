.PHONY: all qz1 qz2

all: qz2

qz1:
	python3 quizs/pow.py -n deweizhai

qz2:
	python3 quizs/pow.py -n deweizhai -z 4 | python3 quizs/encrypt_decrypt.py
