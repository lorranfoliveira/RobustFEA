from __future__ import annotations


class BaseData:

    @classmethod
    def read_dict(cls, dct: dict) -> type(BaseData):
        pass

    def to_dict(self):
        return {}
