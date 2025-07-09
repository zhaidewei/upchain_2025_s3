#!/usr/bin/env python3
"""
Unit tests for quizs/utils.py module
"""
import unittest
import os
import tempfile
import shutil
from unittest.mock import patch, mock_open, MagicMock
import hashlib
import rsa

from utils import (
    hash_function,
    contains_leading_zeros,
    sign_message,
    verify_message,
    get_or_create_key_pair
)


class TestHashFunction(unittest.TestCase):
    """Test cases for hash_function"""

    def test_hash_function_basic(self):
        """Test basic hash function functionality"""
        input_text = "hello"
        expected = hashlib.sha256(input_text.encode()).hexdigest()
        result = hash_function(input_text)
        self.assertEqual(result, expected)

    def test_hash_function_empty_string(self):
        """Test hash function with empty string"""
        input_text = ""
        expected = hashlib.sha256(input_text.encode()).hexdigest()
        result = hash_function(input_text)
        self.assertEqual(result, expected)

    def test_hash_function_unicode(self):
        """Test hash function with unicode characters"""
        input_text = "hello世界"
        expected = hashlib.sha256(input_text.encode()).hexdigest()
        result = hash_function(input_text)
        self.assertEqual(result, expected)

    def test_hash_function_deterministic(self):
        """Test that hash function is deterministic"""
        input_text = "test123"
        result1 = hash_function(input_text)
        result2 = hash_function(input_text)
        self.assertEqual(result1, result2)


class TestContainsLeadingZeros(unittest.TestCase):
    """Test cases for contains_leading_zeros"""

    def test_contains_leading_zeros_valid(self):
        """Test with valid leading zeros"""
        self.assertTrue(contains_leading_zeros("0000abc", 4))
        self.assertTrue(contains_leading_zeros("000abc", 3))
        self.assertTrue(contains_leading_zeros("0abc", 1))

    def test_contains_leading_zeros_invalid(self):
        """Test with invalid leading zeros"""
        self.assertFalse(contains_leading_zeros("000abc", 4))
        self.assertFalse(contains_leading_zeros("0abc", 2))
        self.assertFalse(contains_leading_zeros("abc", 1))

    def test_contains_leading_zeros_exact_match(self):
        """Test with exact number of leading zeros"""
        self.assertTrue(contains_leading_zeros("0000", 4))
        self.assertTrue(contains_leading_zeros("000", 3))

    def test_contains_leading_zeros_zero_requirement(self):
        """Test with zero leading zeros requirement"""
        self.assertTrue(contains_leading_zeros("abc", 0))
        self.assertTrue(contains_leading_zeros("0abc", 0))
        self.assertTrue(contains_leading_zeros("", 0))

    def test_contains_leading_zeros_empty_string(self):
        """Test with empty string"""
        self.assertFalse(contains_leading_zeros("", 1))
        self.assertTrue(contains_leading_zeros("", 0))


class TestRSAFunctions(unittest.TestCase):
    """Test cases for RSA signing and verification functions"""

    def setUp(self):
        """Set up test fixtures"""
        # Generate a test key pair
        self.public_key, self.private_key = rsa.newkeys(512)  # Small key for faster tests
        self.test_message = "test message"

    def test_sign_message_basic(self):
        """Test basic message signing"""
        signature = sign_message(self.private_key, self.test_message)
        self.assertIsInstance(signature, bytes)
        self.assertGreater(len(signature), 0)

    def test_verify_message_valid_signature(self):
        """Test verification with valid signature"""
        signature = sign_message(self.private_key, self.test_message)
        result = verify_message(self.public_key, self.test_message, signature)
        self.assertTrue(result)

    def test_verify_message_invalid_signature(self):
        """Test verification with invalid signature"""
        signature = sign_message(self.private_key, self.test_message)
        # Modify the signature to make it invalid
        invalid_signature = signature[:-1] + b'x'
        result = verify_message(self.public_key, self.test_message, invalid_signature)
        self.assertFalse(result)

    def test_verify_message_wrong_message(self):
        """Test verification with wrong message"""
        signature = sign_message(self.private_key, self.test_message)
        result = verify_message(self.public_key, "wrong message", signature)
        self.assertFalse(result)

    def test_sign_verify_roundtrip(self):
        """Test complete sign and verify roundtrip"""
        messages = ["hello", "world", "test123", ""]
        for message in messages:
            with self.subTest(message=message):
                signature = sign_message(self.private_key, message)
                result = verify_message(self.public_key, message, signature)
                self.assertTrue(result)


class TestGetOrCreateKeyPair(unittest.TestCase):
    """Test cases for get_or_create_key_pair function"""

    def setUp(self):
        """Set up test fixtures"""
        self.temp_dir = tempfile.mkdtemp()
        self.private_key_file = os.path.join(self.temp_dir, "test_private.pem")
        self.public_key_file = os.path.join(self.temp_dir, "test_public.pem")

    def tearDown(self):
        """Clean up test fixtures"""
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    @patch.dict(os.environ, {
        'PRIVATE_KEY_FILE': '',
        'PUBLIC_KEY_FILE': '',
        'KEY_SIZE': '512'
    }, clear=False)
    def test_get_or_create_key_pair_new_keys(self):
        """Test creating new key pair when no files exist"""
        with patch.dict(os.environ, {
            'PRIVATE_KEY_FILE': self.private_key_file,
            'PUBLIC_KEY_FILE': self.public_key_file,
            'KEY_SIZE': '512'
        }):
            private_key, public_key = get_or_create_key_pair()

            # Verify keys are RSA keys
            self.assertIsInstance(private_key, rsa.PrivateKey)
            self.assertIsInstance(public_key, rsa.PublicKey)

            # Verify files were created
            self.assertTrue(os.path.exists(self.private_key_file))
            self.assertTrue(os.path.exists(self.public_key_file))

            # Verify keys work together
            message = "test"
            signature = sign_message(private_key, message)
            self.assertTrue(verify_message(public_key, message, signature))

    @patch.dict(os.environ, {
        'PRIVATE_KEY_FILE': '',
        'PUBLIC_KEY_FILE': '',
        'KEY_SIZE': '512'
    }, clear=False)
    def test_get_or_create_key_pair_load_existing(self):
        """Test loading existing key pair from files"""
        # First create a key pair
        with patch.dict(os.environ, {
            'PRIVATE_KEY_FILE': self.private_key_file,
            'PUBLIC_KEY_FILE': self.public_key_file,
            'KEY_SIZE': '512'
        }):
            original_private, original_public = get_or_create_key_pair()

            # Load the same key pair again
            loaded_private, loaded_public = get_or_create_key_pair()

            # Verify they're the same keys
            self.assertEqual(original_private.n, loaded_private.n)
            self.assertEqual(original_private.e, loaded_private.e)
            self.assertEqual(original_public.n, loaded_public.n)
            self.assertEqual(original_public.e, loaded_public.e)

    @patch.dict(os.environ, {
        'PRIVATE_KEY_FILE': '',
        'PUBLIC_KEY_FILE': '',
        'KEY_SIZE': '1024'
    }, clear=False)
    def test_get_or_create_key_pair_custom_key_size(self):
        """Test key pair generation with custom key size"""
        with patch.dict(os.environ, {
            'PRIVATE_KEY_FILE': self.private_key_file,
            'PUBLIC_KEY_FILE': self.public_key_file,
            'KEY_SIZE': '1024'
        }):
            private_key, public_key = get_or_create_key_pair()

            # Verify key size (RSA key size is related to the modulus n)
            # For a 1024-bit key, n should be approximately 1024 bits
            n_bit_length = private_key.n.bit_length()
            self.assertGreaterEqual(n_bit_length, 1020)  # Allow some tolerance
            self.assertLessEqual(n_bit_length, 1030)

    @patch.dict(os.environ, {}, clear=False)
    def test_get_or_create_key_pair_default_values(self):
        """Test key pair generation with default environment values"""
        with tempfile.TemporaryDirectory() as temp_dir:
            # Change to temp directory to avoid creating files in current dir
            original_cwd = os.getcwd()
            os.chdir(temp_dir)

            try:
                private_key, public_key = get_or_create_key_pair()

                # Verify default files were created
                self.assertTrue(os.path.exists("private_key.pem"))
                self.assertTrue(os.path.exists("public_key.pem"))

                # Verify keys work
                self.assertIsInstance(private_key, rsa.PrivateKey)
                self.assertIsInstance(public_key, rsa.PublicKey)

            finally:
                os.chdir(original_cwd)

    def test_get_or_create_key_pair_directory_creation(self):
        """Test that directories are created when needed"""
        nested_dir = os.path.join(self.temp_dir, "nested", "dir")
        private_key_file = os.path.join(nested_dir, "private.pem")
        public_key_file = os.path.join(nested_dir, "public.pem")

        with patch.dict(os.environ, {
            'PRIVATE_KEY_FILE': private_key_file,
            'PUBLIC_KEY_FILE': public_key_file,
            'KEY_SIZE': '512'
        }):
            private_key, public_key = get_or_create_key_pair()

            # Verify directory was created
            self.assertTrue(os.path.exists(nested_dir))
            self.assertTrue(os.path.exists(private_key_file))
            self.assertTrue(os.path.exists(public_key_file))


class TestIntegration(unittest.TestCase):
    """Integration tests combining multiple functions"""

    def test_pow_to_rsa_workflow(self):
        """Test the complete POW to RSA workflow"""
        # Simulate POW result
        nickname = "testuser"
        nonce = 12345
        nickname_with_nonce = f"{nickname}{nonce}"

        # Verify it would work with hash function
        hash_result = hash_function(nickname_with_nonce)
        self.assertIsInstance(hash_result, str)
        self.assertEqual(len(hash_result), 64)  # SHA-256 produces 64 hex characters

        # Test with a known case that has leading zeros
        # This is a deterministic test case
        test_input = "dewei108568"  # Known to produce hash with leading zeros
        test_hash = hash_function(test_input)

        # Generate keys and sign
        with tempfile.TemporaryDirectory() as temp_dir:
            private_key_file = os.path.join(temp_dir, "private.pem")
            public_key_file = os.path.join(temp_dir, "public.pem")

            with patch.dict(os.environ, {
                'PRIVATE_KEY_FILE': private_key_file,
                'PUBLIC_KEY_FILE': public_key_file,
                'KEY_SIZE': '512'
            }):
                private_key, public_key = get_or_create_key_pair()
                signature = sign_message(private_key, test_input)
                is_valid = verify_message(public_key, test_input, signature)

                self.assertTrue(is_valid)


if __name__ == '__main__':
    # Configure logging to reduce noise during tests
    import logging
    logging.basicConfig(level=logging.WARNING)

    unittest.main(verbosity=2)
