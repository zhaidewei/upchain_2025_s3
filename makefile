hw1:
	python3 quizs/pow.py -n deweizhai

hw2:
	python3 quizs/pow.py -n deweizhai -z 4 | python3 quizs/encrypt_decrypt.py

# Quiz 2 specific: POW with 4 zeros + RSA signing
quiz2:
	python3 quizs/pow.py -n deweizhai -z 4 | python3 quizs/encrypt_decrypt.py
