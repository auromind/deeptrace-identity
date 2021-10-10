import os
import hashlib
import binascii

def hash_password(password: str) -> str:
    """Hash a password for storing."""
    salt = b'__hash__' + hashlib.sha256(os.urandom(60)).hexdigest().encode('ascii')
    pwdhash = hashlib.pbkdf2_hmac('sha512', password.encode('utf-8'),
                                  salt, 100000)
    pwdhash = binascii.hexlify(pwdhash)
    return (salt + pwdhash).decode('ascii')


def is_password_hashed(password: str) -> bool:
    return password.startswith('__hash__') and len(password) == 200


def verify_password(hashed_password: str, provided_password: str) -> bool:
    """Verify a stored password against one provided by user"""
    salt = hashed_password[:72]
    hashed_password = hashed_password[72:]
    pwdhash = hashlib.pbkdf2_hmac('sha512',
                                  provided_password.encode('utf-8'),
                                  salt.encode('ascii'),
                                  100000)
    pwdhash = binascii.hexlify(pwdhash).decode('ascii')
    return pwdhash == hashed_password