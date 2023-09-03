from __future__ import annotations

import json
import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.patches import PathPatch, FancyArrow
import matplotlib.colors as colors
import numpy as np
from matplotlib.collections import PatchCollection
from .data_to_save import SaveData
from compliances import Compliance, ComplianceNominal, ComplianceMu, CompliancePNorm

from .optimizer import Optimizer
from .results import Iteration, ResultIterations, LastIteration
from .structure import Node, Element, Structure


class Modeller:
    def __init__(self, data_to_save: SaveData, structure: Structure, compliance: type(Compliance),
                 optimizer: Optimizer, result: ResultIterations, last_iteration: LastIteration):
        self.data_to_save = data_to_save
        self.compliance = compliance
        self.optimizer = optimizer
        self.result_iterations = result
        self.last_iteration = last_iteration
        self.structure = structure

    @classmethod
    def read_dict(cls, dct: dict)->Modeller:
        data_to_save = SaveData.read_dict(dct['data_to_save'])
        compliance = Compliance.read_dict(dct['compliance'])
        optimizer = Optimizer.read_dict(dct['optimizer'])
        result = ResultIterations.read_dict(dct['result'])
        last_iteration = LastIteration.read_dict(dct['last_iteration'])
        structure = Structure.read_dict(dct['input_structure'])
        return cls(data_to_save=data_to_save,
                   structure=structure,
                   compliance=compliance,
                   optimizer=optimizer,
                   result=result,
                   last_iteration=last_iteration)

    def to_dict(self):
        return {'data_to_save': self.data_to_save.to_dict(),
                'input_structure': self.structure.to_dict(),
                'optimizer': self.optimizer.to_dict(),
                'iterations': self.result_iterations.to_dict(),
                'last_iteration': self.last_iteration.to_dict()}



class DataHandler:
    def __init__(self, filename: str):
        self.filename = filename
        with open(filename, 'r') as file:
            self.data = json.load(file)

    def nodes(self):
        return self.data['input_structure']['nodes']

    def elements(self):
        return self.data['input_structure']['elements']

    def layout_constraints(self):
        layout_constraints = []
        i = 0
        for element in self.elements():
            if (lc_el := element['layout_constraint']) > 0:
                if lc_el <= len(layout_constraints):
                    layout_constraints[lc_el - 1].append([i])
                else:
                    layout_constraints.append([i])
                i += 1


class Plotter:
    def __init__(self, filename, supports_forces_size=5, supports_forces_width=1,
                 mesh_width=0.1, solution_width=0.1, lc_width=1, cutoff=1e-2, plot_supports_and_loads=True):
        self.filename = filename
        self.supports_forces_size = supports_forces_size
        self.supports_forces_width = supports_forces_width
        self.mesh_width = mesh_width
        self.lc_width = lc_width
        self.solution_width = solution_width
        self.cutoff = cutoff
        self.plot_supports_and_loads = plot_supports_and_loads
        with open(filename, 'r') as file:
            self.data = json.load(file)

    def number_of_elements(self):
        return len(self.data['input_structure']['elements'])

    def continuous_colors(self):
        n = self.number_of_elements()
        colors = []

        j = 0
        for i in range(n):
            colors.append(plt.cm.tab20(j))
            j = j + 1 if j < 20 else 0
        return colors

    def x_limits(self):
        nodes = self.data['input_structure']['nodes']
        x_max = max([node['position'][0] for node in nodes])
        x_min = min([node['position'][0] for node in nodes])
        dx = x_max - x_min

        return [x_min - 0.1 * dx, x_max + 0.1 * dx]

    def y_limits(self):
        nodes = self.data['input_structure']['nodes']
        y_max = max([node['position'][1] for node in nodes])
        y_min = min([node['position'][1] for node in nodes])
        dy = y_max - y_min

        return [y_min - 0.1 * dy, y_max + 0.1 * dy]

    def normalized_final_areas(self):
        areas = np.sqrt(np.array(self.data['last_iteration']['areas']))
        areas = areas / max(areas)
        return areas

    def patches_supports(self):
        nodes = self.data['input_structure']['nodes']
        patches = []
        for node in nodes:
            if node['support'][0]:
                v1 = np.array(node['position']) + np.array([-self.supports_forces_size, 0])
                v2 = np.array(node['position']) + np.array([self.supports_forces_size, 0])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor='green', lw=self.supports_forces_width))
            if node['support'][1]:
                v1 = np.array(node['position']) + np.array([0, -self.supports_forces_size])
                v2 = np.array(node['position']) + np.array([0, self.supports_forces_size])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor='green', lw=self.supports_forces_width))
        return patches

    def patches_loads(self):
        nodes = self.data['input_structure']['nodes']
        patches = []
        for node in nodes:
            if node['force'][0] != 0:
                v1 = np.array(node['position']) + np.array([-self.supports_forces_size, 0])
                v2 = np.array(node['position']) + np.array([self.supports_forces_size, 0])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor='magenta', lw=self.supports_forces_width))
            if node['force'][1] != 0:
                v1 = np.array(node['position']) + np.array([0, -self.supports_forces_size])
                v2 = np.array(node['position']) + np.array([0, self.supports_forces_size])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor='magenta', lw=self.supports_forces_width))
        return patches

    def plot_initial_structure(self):
        nodes = self.data['input_structure']['nodes']
        colormap = self.continuous_colors()
        patches = []
        for i, element in enumerate(self.data['input_structure']['elements']):
            node1 = nodes[element['nodes'][0] - 1]
            node2 = nodes[element['nodes'][1] - 1]
            p1 = tuple(node1['position'])
            p2 = tuple(node2['position'])

            if self.data['optimizer']['use_layout_constraint'] and element['layout_constraint'] > 0:
                color = colormap[element['layout_constraint'] - 1]
                lw = self.lc_width
            else:
                color = 'black'
                lw = self.mesh_width

            path = Path([p1, p2], [Path.MOVETO, Path.LINETO])
            patches.append(PathPatch(path, edgecolor=color, lw=lw))

        if self.plot_supports_and_loads:
            patches.extend(self.patches_supports())
            patches.extend(self.patches_loads())

        fig, ax = plt.subplots()
        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        # set x min
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())
        plt.title(f'{self.filename}')

        plt.show()

    def plot_optimized_structure(self, n=10):
        colormap = colors.ListedColormap(plt.cm.jet(np.linspace(0, 1, n)))

        nodes = self.data['input_structure']['nodes']
        areas = self.normalized_final_areas()

        patches = []
        for i, element in enumerate(self.data['input_structure']['elements']):
            if areas[i] >= self.cutoff:
                p1 = tuple(nodes[element['nodes'][0] - 1]['position'])
                p2 = tuple(nodes[element['nodes'][1] - 1]['position'])
                path = Path([p1, p2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor=colormap(areas[i]), lw=areas[i] * self.solution_width))

        fig, ax = plt.subplots()

        if self.plot_supports_and_loads:
            patches.extend(self.patches_supports())
            patches.extend(self.patches_loads())

        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        # set x min
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())
        plt.colorbar(plt.cm.ScalarMappable(cmap=colormap), ax=ax)
        plt.title(f'{self.filename}')

        plt.show()

    def plot_compliance(self):
        compliance = np.array([iteration['compliance'] for iteration in self.data['iterations']])
        plt.plot(compliance)
        plt.xlabel('Iteration')
        plt.ylabel('Compliance')

        plt.show()

    def get_lc_elements(self):
        r = []
        for i, element in enumerate(self.data['input_structure']['elements']):
            if element['layout_constraint'] > 0:
                r.append(i + 1)
        return np.array(r)

    def get_max_lc_area(self, elements_ids):
        return np.max(self.normalized_final_areas()[elements_ids - 1])

    def plot_lc_areas(self, elements_ids, color, title, max_area):
        areas = np.array(self.data['last_iteration']['areas']) / max_area
        fig, ax = plt.subplots()

        patches = []

        used_areas = areas[elements_ids - 1]

        for j, area in enumerate(used_areas):
            patches.append(PathPatch(Path([(j + 1, 0), (j + 1, area)], [Path.MOVETO, Path.LINETO]), lw=1))

        ax.add_collection(PatchCollection(patches, edgecolors=color))
        ax.set_xlim([0, len(used_areas)])
        ax.set_ylim([0, 1.1 * max_area])
        plt.xlabel('Elements')
        plt.ylabel('Areas')
        plt.title(f'{title}')

        plt.show()

    def plot_compare_lc_areas(self, file_without_lc=None):
        x = np.linspace(0.1, 2 * np.pi, 100)
        y = np.exp(np.sin(x))

        plt.scatter(x, y)
        plt.scatter(x, 1.5 * y)
        plt.show()


p0 = Plotter('../final_examples/hook_1.json')

p = Plotter('../final_examples/hook_5.json',
            supports_forces_size=0.75,
            supports_forces_width=1,
            lc_width=2,
            mesh_width=0.1,
            solution_width=6,
            cutoff=1e-4,
            plot_supports_and_loads=True)

p.plot_initial_structure()
p.plot_optimized_structure()
p.plot_compliance()

elements_ids = p.get_lc_elements()
area_max = max(p.get_max_lc_area(elements_ids), p0.get_max_lc_area(elements_ids))

p.plot_lc_areas(elements_ids, 'red', 'Restricted elements', area_max)
p0.plot_lc_areas(elements_ids, 'blue', 'Non-restricted elements', area_max)
