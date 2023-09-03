from .compliances import *
from .base_data import BaseData


class Optimizer(BaseData):
    KEY = 'optimizer'

    def __init__(self, compliance: type(Compliance),
                 volume_max: float = 1.0,
                 min_iterations: int = 20,
                 max_iterations: int = 15000,
                 use_adaptive_move=True,
                 initial_move_multiplier=1.0,
                 use_adaptive_damping=True,
                 initial_damping=True,
                 use_layout_constraint=False,
                 x_min=1e-12,
                 tolerance=1e-8):
        self.compliance = compliance
        self.volume_max = volume_max
        self.min_iterations = min_iterations
        self.max_iterations = max_iterations
        self.use_adaptive_move = use_adaptive_move
        self.initial_move_multiplier = initial_move_multiplier
        self.use_adaptive_damping = use_adaptive_damping
        self.initial_damping = initial_damping
        self.use_layout_constraint = use_layout_constraint
        self.x_min = x_min
        self.tolerance = tolerance

    @classmethod
    def read_dict(cls, dct: dict) -> type(BaseData):
        if (compliance_type := dct[cls.KEY]['compliance']['key']) == 'nominal':
            compliance = ComplianceNominal.read_dict(dct[cls.KEY]['compliance'])
        elif compliance_type == 'mu':
            compliance = ComplianceMu.read_dict(dct[cls.KEY]['compliance'])
        elif compliance_type == 'p_norm':
            compliance = CompliancePNorm.read_dict(dct[cls.KEY]['compliance'])
        else:
            raise ValueError(f'Unknown compliance type: {compliance_type}')

        return cls(compliance=compliance,
                   volume_max=dct[cls.KEY]['volume_max'],
                   min_iterations=dct[cls.KEY]['min_iterations'],
                   max_iterations=dct[cls.KEY]['max_iterations'],
                   use_adaptive_move=dct[cls.KEY]['use_adaptive_move'],
                   initial_move_multiplier=dct[cls.KEY]['initial_move_multiplier'],
                   use_adaptive_damping=dct[cls.KEY]['use_adaptive_damping'],
                   initial_damping=dct[cls.KEY]['initial_damping'],
                   use_layout_constraint=dct[cls.KEY]['use_layout_constraint'],
                   x_min=dct[cls.KEY]['x_min'],
                   tolerance=dct[cls.KEY]['tolerance'])

    def __repr__(self):
        return (f'Optimizer(compliance={self.compliance}, volume_max={self.volume_max}, '
                f'min_iterations={self.min_iterations}, max_iterations={self.max_iterations}, '
                f'use_adaptive_move={self.use_adaptive_move}, initial_move_multiplier={self.initial_move_multiplier}, '
                f'use_adaptive_damping={self.use_adaptive_damping}, initial_damping={self.initial_damping}, '
                f'use_layout_constraint={self.use_layout_constraint}, x_min={self.x_min}, '
                f'tolerance={self.tolerance})')

    def to_dict(self):
        return {'optimizer': {'compliance': self.compliance.key,
                              'volume_max': self.volume_max,
                              'min_iterations': self.min_iterations,
                              'max_iterations': self.max_iterations,
                              'use_adaptive_move': self.use_adaptive_move,
                              'initial_move_multiplier': self.initial_move_multiplier,
                              'use_adaptive_damping': self.use_adaptive_damping,
                              'initial_damping': self.initial_damping,
                              'use_layout_constraints': self.use_layout_constraint,
                              'x_min': self.x_min,
                              'tolerance': self.tolerance}
                }
