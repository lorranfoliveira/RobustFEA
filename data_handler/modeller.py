from __future__ import annotations

import json
import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.patches import PathPatch
from matplotlib.patches import Ellipse
import matplotlib.colors as colors
import numpy as np
from matplotlib.collections import PatchCollection
from .save_data import SaveData
from matplotlib import cm
from .optimizer import Optimizer
from .results import ResultIterations, LastIteration
from .structure import Node, Element, Structure, Material
import ezdxf
from ezdxf.groupby import groupby
from tqdm import tqdm
from scipy.io import savemat

# FONT_SMALL_SIZE = 12
# FONT_MEDIUM_SIZE = 17
# FONT_BIG_SIZE = 20
#
plt.rcParams["font.family"] = "Times New Roman"
# plt.rc('font', size=FONT_SMALL_SIZE)          # controls default text sizes
# plt.rc('axes', titlesize=FONT_SMALL_SIZE)     # fontsize of the axes title
# plt.rc('axes', labelsize=FONT_MEDIUM_SIZE)    # fontsize of the x and y labels
# plt.rc('xtick', labelsize=FONT_SMALL_SIZE)    # fontsize of the tick labels
# plt.rc('ytick', labelsize=FONT_SMALL_SIZE)    # fontsize of the tick labels
# plt.rc('legend', fontsize=FONT_SMALL_SIZE)    # legend fontsize
# plt.rc('figure', titlesize=FONT_BIG_SIZE)  # fontsize of the figure title

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

        color = 0
        for element in self.structure.elements:
            if element.layout_constraint == 0:
                msp.add_line(element.nodes[0].position, element.nodes[1].position,
                             dxfattribs={'layer': 'elements_default'})
            else:
                layer_name = f'elements_lc_{element.layout_constraint}'
                try:
                    doc.layers.get(layer_name)
                except ValueError:
                    color = element.layout_constraint % 6 + 1
                    doc.layers.add(name=layer_name, color=color)
                msp.add_line(element.nodes[0].position, element.nodes[1].position, dxfattribs={'layer': layer_name})

        for node in self.structure.nodes:
            if not (all(s is False for s in node.support) and all(f == 0.0 for f in node.force)):
                layer_name = f'nodes_{node.force[0]}_{node.force[1]}_{node.support[0]}_{node.support[1]}'
                try:
                    doc.layers.get(layer_name)
                except ValueError:
                    color += 1
                    doc.layers.add(name=layer_name, color=color % 6 + 1)

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
        areas = np.sqrt(np.array(self.last_iteration.iteration.areas))
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

    def get_load_markers(self, color: str='gray', factor: float=3.0) -> list[PathPatch]:
        patches = []
        for node in self.structure.nodes:
            if sum(np.abs(node.force)) > 0:
                forces = np.abs(np.array(node.force))
                forces_norm = forces / max(forces)
                fx = factor * forces_norm[0]
                fy = factor * forces_norm[1]
                
                el = Ellipse(xy=node.position, width=fx, height=fy, angle=0.0, edgecolor=color, lw=0)
                el.set_alpha(0.5)
                patches.append(el)

            #if node.force[0] != 0:
             #   v1 = np.array(node.position) + np.array([-size, 0])
             #   v2 = np.array(node.position) + np.array([size, 0])
             #   path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
            #    patches.append(PathPatch(path, edgecolor=color, lw=width))
           # if node.force[1] != 0:
            #    v1 = np.array(node.position) + np.array([0, -size])
             #   v2 = np.array(node.position) + np.array([0, size])
            #    path = Path([v1, v2], [Path.MOVETO, Path.LINETO])
             #   patches.append(PathPatch(path, edgecolor=color, lw=width))
        return patches

    def get_restricted_elements(self) -> dict[int, list[int]]:
        data = {}
        for element in self.structure.elements:
            if (lc := element.layout_constraint) > 0:
                if lc in data:
                    data[lc].append(element.idt)
                else:
                    data[lc] = [element.idt]
        return dict(sorted(data.items()))

    def plot_dv_analysis(self, other: Modeller, width: float = 5.0):
        lcs = self.get_restricted_elements()

        if len(lcs) > 0:
            self_areas = np.array(self.last_iteration.iteration.areas)
            other_areas = np.array(other.last_iteration.iteration.areas)
            max_abs_area = max(self_areas.max(), other_areas.max())
            self_areas = self_areas / max_abs_area
            other_areas = other_areas / max_abs_area

            self_patches = []
            other_patches = []
            max_lc_norm_area = -np.inf
            i = 0
            for lc in lcs:
                for el_id in lcs[lc]:
                    area_self = self_areas[el_id - 1]
                    area_other = other_areas[el_id - 1]

                    max_lc_norm_area = max([max_lc_norm_area, area_self, area_other])

                    self_path = Path([[i, 0], [i, area_self]], [Path.MOVETO, Path.LINETO])
                    other_path = Path([[i, 0], [i, area_other]], [Path.MOVETO, Path.LINETO])

                    self_patches.append(PathPatch(self_path, edgecolor=cm.tab20(lc % 20), lw=width))
                    other_patches.append(PathPatch(other_path, edgecolor=cm.tab20(lc % 20), lw=width))
                    i += 1

            n_lc_els = sum([len(lcs[lc]) for lc in lcs])
            fig, ax = plt.subplots(2, 1)

            ax[0].add_collection(PatchCollection(self_patches, match_original=True))
            ax[0].set_xlim(0, n_lc_els)
            ax[0].set_ylim(0, 1.1 * max_lc_norm_area)
            ax[0].set_xlabel('Element')
            ax[0].set_ylabel('Normalized area')
            ax[0].set_title(f'Case {self.filename.split("_")[-1].replace(".json", "")}')

            ax[1].add_collection(PatchCollection(other_patches, match_original=True))
            ax[1].set_xlim(0, n_lc_els)
            ax[1].set_ylim(0, 1.1 * max_lc_norm_area)
            ax[1].set_xlabel('Element')
            ax[1].set_ylabel('Normalized area')
            ax[1].set_title(f'Case {other.filename.split("_")[-1].replace(".json", "")}')

            # fig.suptitle(f'Areas analysis: {self.filename.replace(".json", "")}  '
            #              f'({other.filename.replace(".json", "")} as reference)')
            fig.tight_layout()
            plt.show()
        else:
            raise ValueError('No layout constraints found')

    def plot_initial_structure(self, default_width: float, lc_width: float, supports_markers_width: float,
                               supports_markers_size: float, forces_markers_size: float,
                               plot_supports: bool = True, plot_loads: bool = True,
                               supports_markers_color: str = 'green',
                               forces_markers_color: str = 'gray'):
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
            patches.extend(self.get_load_markers(factor=forces_markers_size, color=forces_markers_color))

        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())
        # plt.title(f'Initial structure - {self.filename.replace(".json", "")}')
        plt.show()

    def plot_optimized_structure(self, base_width: float = 1.0, cutoff: float = 1e-4, plot_supports: bool = True,
                                 plot_loads: bool = True, supports_markers_width: float = 4.0,
                                 supports_markers_size: float = 0.05, supports_markers_color: str = 'green',
                                 forces_markers_size: float = 0.05, forces_markers_color: str = 'gray'):
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
            patches.extend(self.get_load_markers(factor=forces_markers_size, color=forces_markers_color))

        ax.add_collection(PatchCollection(patches, match_original=True))
        ax.set_aspect('equal')
        ax.axis('off')
        ax.set_xlim(self.x_limits())
        ax.set_ylim(self.y_limits())
        #ax.set_title(f'elements: {len(self.structure.elements)} file: {self.filename}')
        # plt.title(f'Optimized structure - {self.filename.replace(".json", "")}')
        plt.colorbar(plt.cm.ScalarMappable(cmap=colormap), ax=ax, shrink=0.5)
        plt.show()
        #plt.savefig(self.filename.replace(".json", ".png"), dpi=300)

    def plot_compliance(self):
        compliance = np.array([iteration.compliance for iteration in self.result_iterations.iterations])
        plt.plot(compliance)
        plt.xlabel('Iteration')
        plt.ylabel('Compliance')
        # plt.title(f'Compliance - {self.filename.replace(".json", "")}')
        plt.show()

    def save_mat_file(self):
        data = {'fem': {'NNode': len(self.structure.nodes),
                        'NElem': len(self.structure.elements),
                        'Vol': self.optimizer.volume_max}}

        for node in self.structure.nodes:
            node_dict = {'cg': node.force,
                         'sup': [int(s) for s in node.support],
                         'x': node.position[0],
                         'y': node.position[1]}

            if 'Node' in data['fem']:
                data['fem']['Node'].append(node_dict)
            else:
                data['fem']['Node'] = [node_dict]

        for element in self.structure.elements:
            element_dict = {'nodes': [el.idt for el in element.nodes],
                            'E': element.area,
                            'A': element.nodes[0].idt,
                            'L': element.length()}

            if 'Element' in data['fem']:
                data['fem']['Element'].append(element_dict)
            else:
                data['fem']['Element'] = [element_dict]

        savemat(f'{self.filename.replace(".json", ".mat")}', data)
