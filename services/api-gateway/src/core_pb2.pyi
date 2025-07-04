from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class MovePlayerRequest(_message.Message):
    __slots__ = ("user_id", "target_x", "target_y")
    USER_ID_FIELD_NUMBER: _ClassVar[int]
    TARGET_X_FIELD_NUMBER: _ClassVar[int]
    TARGET_Y_FIELD_NUMBER: _ClassVar[int]
    user_id: str
    target_x: int
    target_y: int
    def __init__(self, user_id: _Optional[str] = ..., target_x: _Optional[int] = ..., target_y: _Optional[int] = ...) -> None: ...

class MovePlayerResponse(_message.Message):
    __slots__ = ("success", "message")
    SUCCESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    success: bool
    message: str
    def __init__(self, success: bool = ..., message: _Optional[str] = ...) -> None: ...
