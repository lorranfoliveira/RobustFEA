from __future__ import annotations

import json
import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.patches import PathPatch, FancyArrow
import matplotlib.colors as colors
import numpy as np
from matplotlib.collections import PatchCollection
from .save_data import SaveData
from .compliances import Compliance, ComplianceNominal, ComplianceMu, CompliancePNorm

from .optimizer import Optimizer
from .results import Iteration, ResultIterations, LastIteration
from .structure import Node, Element, Structure, Material
import ezdxf
from ezdxf.groupby import groupby
from tqdm import tqdm


class Modeller:
    def __init__(self, filename: str, data_to_save: SaveData, optimizer: Optimizer,
                 result: ResultIterations | None = None, last_iteration: LastIteration | None = None,
                 structure: Structure | None = None):
        self.filename = filename
        self.data_to_save = data_to_save
        self.optimizer = optimizer
        self.result_iterations = result
        self.last_iteration = last_iteration
        self.structure = structure

    @classmethod
    def read(cls, filename: str) -> Modeller:
        with open(filename, 'r') as file:
            file_data = json.load(file)

        data_to_save = SaveData.read_dict(file_data)
        optimizer = Optimizer.read_dict(file_data)
        result = ResultIterations.read_dict(file_data)
        last_iteration = LastIteration.read_dict(file_data)
        structure = Structure.read_dict(file_data['input_structure'])
        return cls(filename=filename,
                   data_to_save=data_to_save,
                   structure=structure,
                   optimizer=optimizer,
                   result=result,
                   last_iteration=last_iteration)

    def to_dict(self):
        result = {}
        try:
            result.update({'result_iterations': self.result_iterations.to_dict()})
        except AttributeError:
            pass

        try:
            result.update({'last_iteration': self.last_iteration.to_dict()})
        except AttributeError:
            pass

        result.update({'data_to_save': self.data_to_save.to_dict(),
                       'input_structure': self.structure.to_dict(),
                       'optimizer': self.optimizer.to_dict()})
        return result

    def write(self):
        with open(self.filename, 'w') as file:
            json.dump(self.to_dict(), file)

    def read_structure_from_dxf(self, elements_material: Material, elements_area: float = 1.0):
        layers = groupby(entities=ezdxf.readfile(f'{self.filename.replace(".json", ".dxf")}').modelspace(),
                         dxfattrib='layer')
        nodes = []
        nodes_info = []
        # Elements info: (id, node1, node2, lc_id)
        elements = []
        el_id = 1
        for layer in tqdm(layers.keys(), desc='Reading dxf file'):
            if layer.startswith('elements'):
                for entity in tqdm(layers[layer], desc=f'Reading "{layer}"'):
                    lc_id = 0
                    if (node1 := entity.dxf.start) not in nodes:
                        nodes.append(tuple(node1)[:2])

                    if (node2 := entity.dxf.end) not in nodes:
                        nodes.append(tuple(node2)[:2])

                    if 'lc' in layer:
                        lc_id = int(layer[-1])

                    elements.append((el_id, nodes.index(node1) + 1, nodes.index(node2) + 1, lc_id))
                    el_id += 1

            if layer.startswith('nodes'):
                for entity in layers[layer]:
                    if (node := tuple(entity.dxf.location)[:2]) not in nodes:
                        nodes.append(node)
                    info = layer.split('_')
                    nodes_info.append((nodes.index(node), float(info[1]), float(info[2]), bool(info[3]), bool(info[4])))

        # Creating structure
        nodes_structure = []
        for i, node in enumerate(nodes):
            nodes_structure.append(Node(idt=i + 1, position=node, force=[0.0, 0.0],
                                        support=[False, False]))

        for node_info in nodes_info:
            nodes_structure[node_info[0]].force = [node_info[1], node_info[2]]
            nodes_structure[node_info[0]].support = [node_info[3], node_info[4]]

        elements_structure = []
        for element in elements:
            elements_structure.append(Element(idt=element[0],
                                              nodes=[nodes_structure[element[1] - 1], nodes_structure[element[2] - 1]],
                                              material=elements_material, area=elements_area,
                                              layout_constraint=element[3]))

        self.structure = Structure(nodes=nodes_structure, elements=elements_structure, materials=[elements_material])

    def write_dxf(self):
        doc = ezdxf.new('R2010', setup=True)
        msp = doc.modelspace()
        doc.layers.add(name='elements_default', dxfattribs={'color': 7})

        color = 1
        for element in self.structure.elements:
            if element.layout_constraint == 0:
                msp.add_line(element.nodes[0].position, element.nodes[1].position,
                             dxfattribs={'layer': 'elements_default'})
            else:
                layer_name = f'elements_lc_{element.layout_constraint}'
                try:
                    doc.layers.get(layer_name)
                except ValueError:
                    doc.layers.add(name=layer_name, color=color)
                    color = color + 1 if color <= 6 else 1
                msp.add_line(element.nodes[0].position, element.nodes[1].position,
                             dxfattribs={'layer': layer_name})

        for node in self.structure.nodes:
            if not (node.support == [False, False] and node.force == [0.0, 0.0]):
                layer_name = f'nodes_{node.force[0]}_{node.force[1]}_{node.support[0]}_{node.support[1]}'
                try:
                    doc.layers.get(layer_name)
                except ValueError:
                    doc.layers.add(name=layer_name, color=color)
                    color = color + 1 if color <= 6 else 1

                msp.add_point(node.position, dxfattribs={'layer': layer_name})

        # doc.saveas(f'{self.filename.replace(".json", ".dxf")}')
        doc.saveas(f'teste.dxf')
