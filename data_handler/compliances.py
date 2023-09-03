from __future__ import annotations

from .base_data import BaseData


class Compliance(BaseData):
    _KEY = ''

    @property
    def key(self) -> str:
        return self._KEY

    @classmethod
    def read_dict(cls, dct: dict) -> type(Compliance):
        pass

    def to_dict(self):
        return {'key': self.key}


class ComplianceNominal(Compliance):
    _KEY = 'nominal'

    @classmethod
    def read_dict(cls, dct: dict) -> type(Compliance):
        return cls()

    def to_dict(self):
        return {'key': self.key}


class ComplianceMu(Compliance):
    _KEY = 'mu'

    def __init__(self, beta: float = 0.1):
        super().__init__()
        self.beta = beta

    @classmethod
    def read_dict(cls, dct: dict) -> type(Compliance):
        return cls(beta=dct['parameters']['beta'])

    def to_dict(self):
        dct = super().to_dict()
        dct['beta'] = self.beta
        return dct


class CompliancePNorm(Compliance):
    _KEY = 'p_norm'

    def __init__(self, p: float = 20):
        super().__init__()
        self.p = p

    @classmethod
    def read_dict(cls, dct: dict) -> type(Compliance):
        return cls(p=dct['parameters']['p'])

    def to_dict(self):
        dct = super().to_dict()
        dct['p'] = self.p
        return dct
