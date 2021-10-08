"""
https://python.plainenglish.io/how-to-use-fastapi-with-mongodb-75b43c8e541d
https://www.youtube.com/watch?v=wM7NJtQ0F6U
"""
from pydantic import BaseModel, Field, validator
from pymongo import MongoClient
from bson import ObjectId
from typing import Optional

import os
import hashlib
import binascii

client = MongoClient("mongodb://admin:secret@localhost")
db = client['deeptrace']



def hash_password(password: str) -> str:
    """Hash a password for storing."""
    salt = b'__hash__' + hashlib.sha256(os.urandom(60)).hexdigest().encode('ascii')
    pwdhash = hashlib.pbkdf2_hmac('sha512', password.encode('utf-8'),
                                  salt, 100000)
    pwdhash = binascii.hexlify(pwdhash)
    return (salt + pwdhash).decode('ascii')


def is_hash(pw: str) -> bool:
    return pw.startswith('__hash__') and len(pw) == 200


def verify_password(stored_password: str, provided_password: str) -> bool:
    """Verify a stored password against one provided by user"""
    salt = stored_password[:72]
    stored_password = stored_password[72:]
    pwdhash = hashlib.pbkdf2_hmac('sha512',
                                  provided_password.encode('utf-8'),
                                  salt.encode('ascii'),
                                  100000)
    pwdhash = binascii.hexlify(pwdhash).decode('ascii')
    return pwdhash == stored_password



class PyObjectId(ObjectId):

    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError('Invalid objectid')
        return ObjectId(v)

    @classmethod
    def __modify_schema__(cls, field_schema):
        field_schema.update(type='string')


class User(BaseModel):
    id: Optional[PyObjectId] = Field(alias='_id')
    email: str
    password: str

    @validator('password')
    def hash_password(cls, pw: str) -> str:
        if is_hash(pw):
            return pw
        return hash_password(pw)


    class Config:
        arbitrary_types_allowed = True
        json_encoders = {
            ObjectId: str
        }

class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None