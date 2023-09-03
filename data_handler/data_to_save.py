from .base_data import BaseData


class SaveData(BaseData):
    def __init__(self, step=1, save_angles: bool = False, save_areas: bool = False, save_forces: bool = False,
                 save_compliance: bool = True, save_move: bool = False, save_volume: bool = False,
                 save_error: bool = False):
        self.step = step
        self.save_angles = save_angles
        self.save_areas = save_areas
        self.save_forces = save_forces
        self.save_compliance = save_compliance
        self.save_move = save_move
        self.save_volume = save_volume
        self.save_error = save_error

    def __repr__(self):
        return f'SaveData(step={self.step}, save_angles={self.save_angles}, save_areas={self.save_areas}, ' \
               f'save_forces={self.save_forces}, save_compliance={self.save_compliance}, save_move={self.save_move}, ' \
               f'save_volume={self.save_volume}, save_error={self.save_error})'

    @classmethod
    def read_dict(cls, dct: dict) -> type(BaseData):
        return cls(step=dct['step'],
                   save_angles=dct['save_angles'],
                   save_areas=dct['save_areas'],
                   save_forces=dct['save_forces'],
                   save_compliance=dct['save_compliance'],
                   save_move=dct['save_move'],
                   save_volume=dct['save_volume'],
                   save_error=dct['save_error'])

    def to_dict(self):
        return {'step': self.step,
                'save_angles': self.save_angles,
                'save_areas': self.save_areas,
                'save_forces': self.save_forces,
                'save_compliance': self.save_compliance,
                'save_move': self.save_move,
                'save_volume': self.save_volume,
                'save_error': self.save_error}
