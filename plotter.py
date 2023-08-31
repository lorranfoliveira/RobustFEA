import json
import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.patches import PathPatch, FancyArrow
import matplotlib.colors as colors
import numpy as np
from matplotlib.collections import PatchCollection


class Plotter:
    def __init__(self, filename, supports_size=5, supports_width=1, load_size=5, load_width=5, cutoff=1e-2, ):
        self.filename = filename
        self.supports_size = supports_size
        self.supports_width = supports_width
        self.cutoff = cutoff
        self.load_size = load_size
        self.load_width = load_width
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
        areas = np.array(self.data['iterations'][-1]['areas'])
        areas = areas / max(areas)
        return areas

    def patches_supports(self):
        nodes = self.data['input_structure']['nodes']
        patches = []
        for node in nodes:
            if node['support'][0]:
                v1 = np.array(node['position']) + np.array([-self.supports_size, 0])
                v2 = np.array(node['position']) + np.array([self.supports_size, 0])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor='green', lw=self.supports_width))
            if node['support'][1]:
                v1 = np.array(node['position']) + np.array([0, -self.supports_size])
                v2 = np.array(node['position']) + np.array([0, self.supports_size])
                path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor='green', lw=self.supports_width))
        return patches

    def patches_loads_initial_structure(self):
        nodes = self.data['input_structure']['nodes']
        patches = []
        for node in nodes:
            if node['force'][0] != 0 or node['force'][1] != 0:
                p = np.array(node['position'])
                dx = node['force'][0] * self.load_size
                dy = node['force'][1] * self.load_size
                arrow = FancyArrow(p[0], p[1], dx, dy, length_includes_head=True, color='blue', width=self.load_width)
                patches.append(arrow)
        return patches

    def patches_loads_optimized_structure(self):
        nodes = self.data['input_structure']['nodes']
        forces = np.array(self.data['iterations'][-1]['forces']).reshape(-1, 2)
        patches = []
        for force, node in zip(forces, nodes):
            if force[0] != 0 or force[1] != 0:
                p = np.array(node['position'])
                dx = node['force'][0] * self.load_size
                dy = node['force'][1] * self.load_size
                arrow = FancyArrow(p[0], p[1], dx, dy, length_includes_head=True, color='purple', width=self.load_width)
                patches.append(arrow)
        return patches

    def plot_initial_structure(self, line_width=5):
        nodes = self.data['input_structure']['nodes']
        colormap = self.continuous_colors()
        patches = []
        for i, element in enumerate(self.data['input_structure']['elements']):
            node1 = nodes[element['nodes'][0] - 1]
            node2 = nodes[element['nodes'][1] - 1]
            p1 = tuple(node1['position'])
            p2 = tuple(node2['position'])

            color = colormap[element['layout_constraint'] - 1] if element['layout_constraint'] > 0 else 'black'

            path = Path([p1, p2], [Path.MOVETO, Path.LINETO])
            patches.append(PathPatch(path, edgecolor=color, lw=line_width))

        patches.extend(self.patches_supports())
        patches.extend(self.patches_loads_initial_structure())

        fig, ax = plt.subplots()
        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        # set x min
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())

        plt.show()

    def plot_optimized_structure(self, line_width=5, cutoff=1e-2, n=10):
        colormap = colors.ListedColormap(plt.cm.jet(np.linspace(0, 1, n)))

        nodes = self.data['input_structure']['nodes']
        areas = self.normalized_final_areas()

        patches = []
        for i, element in enumerate(self.data['input_structure']['elements']):
            if areas[i] >= cutoff:
                p1 = tuple(nodes[element['nodes'][0] - 1]['position'])
                p2 = tuple(nodes[element['nodes'][1] - 1]['position'])
                path = Path([p1, p2], [Path.MOVETO, Path.LINETO])
                patches.append(PathPatch(path, edgecolor=colormap(areas[i]), lw=areas[i] * line_width))

        fig, ax = plt.subplots()
        patches.extend(self.patches_supports())
        patches.extend(self.patches_loads_optimized_structure())
        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        # set x min
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())
        plt.colorbar(plt.cm.ScalarMappable(cmap=colormap), ax=ax)

        plt.show()

    def plot_compliance(self):
        compliance = np.array([iteration['compliance'] for iteration in self.data['iterations']])
        plt.plot(compliance)
        plt.xlabel('Iteration')
        plt.ylabel('Compliance')
        plt.show()

    def plot_areas_histogram(self, n=10):
        areas = np.array([iteration['areas'] for iteration in self.data['iterations']])
        fig, ax = plt.subplots()
        ax.hist(areas, bins=n)

        plt.xlabel('Area')
        plt.ylabel('Number of elements')
        plt.show()


p = Plotter('example_output.json',
            supports_size=0.05,
            supports_width=4,
            load_size=0.1,
            load_width=0.01)
p.plot_optimized_structure()
