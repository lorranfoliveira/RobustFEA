from __future__ import annotations
from .base_data import BaseData


class Iteration(BaseData):
    def __int__(self, idt: int, angles: list[float] | None = None, areas: list[float] | None = None,
                forces: list[float] | None = None, compliance: float | None = None, move: list[float] | None = None,
                volume: float | None = None, error: float | None = None):
        self.idt = idt
        self.angles = angles
        self.areas = areas
        self.forces = forces
        self.compliance = compliance
        self.move = move
        self.volume = volume
        self.error = error

    @classmethod
    def read_dict(cls, dct: dict) -> Iteration:
        idt = dct['idt']
        try:
            angles = dct['angles']
        except KeyError:
            angles = None

        try:
            areas = dct['areas']
        except KeyError:
            areas = None

        try:
            forces = dct['forces']
        except KeyError:
            forces = None

        try:
            compliance = dct['compliance']
        except KeyError:
            compliance = None

        try:
            move = dct['move']
        except KeyError:
            move = None

        try:
            volume = dct['volume']
        except KeyError:
            volume = None

        try:
            error = dct['error']
        except KeyError:
            error = None

        return cls(idt=idt,
                   angles=angles,
                   areas=areas,
                   forces=forces,
                   compliance=compliance,
                   move=move,
                   volume=volume,
                   error=error)

    def to_dict(self):
        return {'idt': self.idt,
                'angles': self.angles,
                'areas': self.areas,
                'forces': self.forces,
                'compliance': self.compliance,
                'move': self.move,
                'volume': self.volume,
                'error': self.error}


class ResultIterations(BaseData):
    def __init__(self, iterations: list[Iteration]):
        self.iterations = iterations
        super().__init__()

    @classmethod
    def read_dict(cls, dct: dict) -> ResultIterations:
        iterations = []
        for iteration in dct['iterations']:
            iterations.append(Iteration.read_dict(iteration))
        return cls(iterations=iterations)


class LastIteration(BaseData):
    def __init__(self, last_iteration: Iteration):
        self.last_iteration = last_iteration
        super().__init__()

    @classmethod
    def read_dict(cls, dct: dict) -> LastIteration:
        return cls(last_iteration=Iteration.read_dict(dct['last_iteration']))

    def to_dict(self):
        return {'last_iteration': self.last_iteration.to_dict()}
