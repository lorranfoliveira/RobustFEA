from __future__ import annotations

import json
import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.patches import PathPatch, FancyArrow
import matplotlib.colors as colors
import numpy as np
from matplotlib.collections import PatchCollection
from .data_to_save import SaveData
from .compliances import Compliance, ComplianceNominal, ComplianceMu, CompliancePNorm

from .optimizer import Optimizer
from .results import Iteration, ResultIterations, LastIteration
from .structure import Node, Element, Structure


class Modeller:
    def __init__(self, data_to_save: SaveData, structure: Structure, optimizer: Optimizer, result: ResultIterations,
                 last_iteration: LastIteration):
        self.data_to_save = data_to_save
        self.optimizer = optimizer
        self.result_iterations = result
        self.last_iteration = last_iteration
        self.structure = structure

    @classmethod
    def read_dict(cls, filename: str) -> Modeller:
        with open(filename, 'r') as file:
            file_data = json.load(file)

        data_to_save = SaveData.read_dict(file_data['save_data'])
        optimizer = Optimizer.read_dict(file_data)
        result = ResultIterations.read_dict(file_data['iterations'])
        last_iteration = LastIteration.read_dict(file_data['last_iteration'])
        structure = Structure.read_dict(file_data['input_structure'])
        return cls(data_to_save=data_to_save,
                   structure=structure,
                   optimizer=optimizer,
                   result=result,
                   last_iteration=last_iteration)

    def to_dict(self):
        return {'data_to_save': self.data_to_save.to_dict(),
                'input_structure': self.structure.to_dict(),
                'optimizer': self.optimizer.to_dict(),
                'iterations': self.result_iterations.to_dict(),
                'last_iteration': self.last_iteration.to_dict()}
