from __future__ import annotations

import json
import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.patches import PathPatch, FancyArrow
import matplotlib.colors as colors
from matplotlib import cm
import numpy as np
from matplotlib.collections import PatchCollection
from .save_data import SaveData
from .compliances import Compliance, ComplianceNominal, ComplianceMu, CompliancePNorm

from matplotlib import cm
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

        try:
            result = ResultIterations.read_dict(file_data)
        except KeyError:
            result = None

        try:
            last_iteration = LastIteration.read_dict(file_data)
        except KeyError:
            last_iteration = None

        data_to_save = SaveData.read_dict(file_data)
        optimizer = Optimizer.read_dict(file_data)
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

        result.update({'save_data': self.data_to_save.to_dict(),
                       'input_structure': self.structure.to_dict(),
                       'optimizer': self.optimizer.to_dict()})
        return result

    def write_json(self):
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
            layer_info = layer.split('_')
            if layer_info[0] == 'elements':
                for entity in tqdm(layers[layer], desc=f'Reading "{layer}"'):
                    lc_id = 0
                    if (node1 := entity.dxf.start) not in nodes:
                        nodes.append(tuple(node1)[:2])

                    if (node2 := entity.dxf.end) not in nodes:
                        nodes.append(tuple(node2)[:2])

                    if 'lc' in layer_info:
                        lc_id = int(layer_info[-1])

                    elements.append((el_id, nodes.index(node1) + 1, nodes.index(node2) + 1, lc_id))
                    el_id += 1

            if layer_info[0] == 'nodes':
                for entity in layers[layer]:
                    if (node := tuple(entity.dxf.location)[:2]) not in nodes:
                        nodes.append(node)
                    info = layer.split('_')
                    nodes_info.append((nodes.index(node), float(info[1]), float(info[2]), info[3] == "True",
                                       info[4] == "True"))

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

        for element in self.structure.elements:
            if element.layout_constraint == 0:
                msp.add_line(element.nodes[0].position, element.nodes[1].position,
                             dxfattribs={'layer': 'elements_default'})
            else:
                layer_name = f'elements_lc_{element.layout_constraint}'
                try:
                    doc.layers.get(layer_name)
                except ValueError:
                    doc.layers.add(name=layer_name, color=element.layout_constraint % 6 + 1)
                msp.add_line(element.nodes[0].position, element.nodes[1].position, dxfattribs={'layer': layer_name})

        node_layers = 0
        for node in self.structure.nodes:
            if not (all(s is False for s in node.support) and all(f == 0.0 for f in node.force)):
                layer_name = f'nodes_{node.force[0]}_{node.force[1]}_{node.support[0]}_{node.support[1]}'
                try:
                    doc.layers.get(layer_name)
                except ValueError:
                    node_layers += 1
                    doc.layers.add(name=layer_name, color=node_layers % 6 + 1)

                msp.add_point(node.position, dxfattribs={'layer': layer_name})

        doc.saveas(f'{self.filename.replace(".json", ".dxf")}')

    def x_limits(self) -> tuple[float, float]:
        x_min = min([node.position[0] for node in self.structure.nodes])
        x_max = max([node.position[0] for node in self.structure.nodes])
        return x_min - 0.1 * (x_max - x_min), x_max + 0.1 * (x_max - x_min)

    def y_limits(self) -> tuple[float, float]:
        y_min = min([node.position[1] for node in self.structure.nodes])
        y_max = max([node.position[1] for node in self.structure.nodes])
        return y_min - 0.1 * (y_max - y_min), y_max + 0.1 * (y_max - y_min)

    def last_iteration_norm_areas(self) -> np.ndarray:
        areas = np.array(self.last_iteration.iteration.areas)
        return areas / areas.max()

    def get_support_markers(self, size: float, width: float, color: str) -> list[PathPatch]:
        patches = []
        for node in self.structure.nodes:
            if node.support[0]:
                v1 = np.array(node.position) + np.array([-size, 0])
                v2 = np.array(node.position) + np.array([size, 0])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor=color, lw=width))
            if node.support[1]:
                v1 = np.array(node.position) + np.array([0, -size])
                v2 = np.array(node.position) + np.array([0, size])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor=color, lw=width))
        return patches

    def get_load_markers(self, size: float, width: float, color: str) -> list[PathPatch]:
        patches = []
        for node in self.structure.nodes:
            if node.force[0] != 0:
                v1 = np.array(node.position) + np.array([-size, 0])
                v2 = np.array(node.position) + np.array([size, 0])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor=color, lw=width))
            if node.force[1] != 0:
                v1 = np.array(node.position) + np.array([0, -size])
                v2 = np.array(node.position) + np.array([0, size])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor=color, lw=width))
        return patches

    def plot_initial_structure(self, default_width: float, lc_width: float, supports_markers_width: float,
                               supports_markers_size: float, forces_markers_width: float, forces_markers_size: float,
                               plot_supports: bool = True, plot_loads: bool = True,
                               supports_markers_color: str = 'green',
                               forces_markers_color: str = 'magenta'):
        patches = []
        for element in self.structure.elements:
            p1 = element.nodes[0].position
            p2 = element.nodes[1].position
            path = Path([p1, p2], [Path.MOVETO, Path.LINETO])

            if (lc := element.layout_constraint) == 0:
                color = 'black'
                width = default_width
            else:
                color = cm.tab20(lc % 20)
                width = lc_width

            patches.append(PathPatch(path, edgecolor=color, lw=width))

        fig, ax = plt.subplots()

        if plot_supports:
            patches.extend(self.get_support_markers(supports_markers_size, supports_markers_width,
                                                    supports_markers_color))
        if plot_loads:
            patches.extend(self.get_load_markers(forces_markers_size, forces_markers_width, forces_markers_color))

        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())
        plt.title(f'Initial structure - {self.filename.replace(".json", "")}')
        plt.show()

    def plot_optimized_structure(self, base_width: float = 1.0, cutoff: float = 1e-4, plot_supports: bool = True,
                                 plot_loads: bool = True, supports_markers_width: float = 4.0,
                                 supports_markers_size: float = 0.05, supports_markers_color: str = 'green',
                                 forces_markers_width: float = 4.0, forces_markers_size: float = 0.05,
                                 forces_markers_color: str = 'magenta'):
        colormap = colors.ListedColormap(plt.cm.jet(np.linspace(0, 1, 10)))
        patches = []
        areas = self.last_iteration_norm_areas()
        for i, element in enumerate(self.structure.elements):
            if areas[i] > cutoff:
                p1 = element.nodes[0].position
                p2 = element.nodes[1].position
                path = Path([p1, p2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor=colormap(areas[i]), lw=base_width * areas[i]))

        fig, ax = plt.subplots()

        if plot_supports:
            patches.extend(self.get_support_markers(supports_markers_size, supports_markers_width,
                                                    supports_markers_color))
        if plot_loads:
            patches.extend(self.get_load_markers(forces_markers_size, forces_markers_width, forces_markers_color))

        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())
        plt.title(f'Optimized structure - {self.filename.replace(".json", "")}')
        plt.show()
