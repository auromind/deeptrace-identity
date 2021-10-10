"""
https://python.plainenglish.io/how-to-use-fastapi-with-mongodb-75b43c8e541d
https://www.youtube.com/watch?v=wM7NJtQ0F6U
"""
from pydantic import BaseModel, Field, validator
from pydantic.typing import is_new_type
from pymongo import MongoClient
from bson import ObjectId
from typing import Optional


from .auth import hash_password, verify_password, is_password_hashed


client = MongoClient("mongodb://admin:secret@localhost")
db = client['deeptrace']


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




class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


class Password(str):

    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def __modify_schema__(cls, field_schema):
        field_schema.update(
            # Some examples of passwords.
            examples=["password1234"],
        )

    @classmethod
    def validate(cls, v):
        if not isinstance(v, str):
            raise TypeError('string required;')
        if is_password_hashed(v):
            return cls(v)
        else:
            return cls(hash_password(v))

    def __repr__(self):
        return f'Password({super().__repr__()})'

    def __eq__(self, other) -> bool:
        return verify_password(self, other)

class Email(str):

    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def __modify_schema__(cls, field_schema):
        field_schema.update(
            # Some examples of emails.
            examples=["nick@gmail.com"],
        )

    @classmethod
    def validate(cls, v):
        if not isinstance(v, str):
            raise TypeError('string required;')
        return cls(v)

    def __repr__(self):
        return f'Email({super().__repr__()})'


class UserOut(BaseModel):
    email: Email

class UserIn(UserOut):
    password: Password

class User(UserIn):
    id: Optional[PyObjectId] = Field(alias='_id')

    class Config:
        arbitrary_types_allowed = True
        json_encoders = {
            ObjectId: str
        }