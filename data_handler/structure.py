from __future__ import annotations
from .base_data import BaseData
import numpy as np


class Node(BaseData):
    def __init__(self, idt: int, position: list[float], force: list[float] | tuple[float] = (0.0, 0.0),
                 support: list[bool] | tuple[bool] = (False, False)):
        self.idt = idt
        self.position = position
        self.force = force
        self.support = support

    def __repr__(self):
        return f'Node(idt={self.idt}, position={self.position}, force={self.force}, support={self.support})'

    @classmethod
    def read_dict(cls, dct: dict) -> Node:
        return cls(**dct)

    def to_dict(self):
        return {'idt': self.idt,
                'position': self.position,
                'force': self.force,
                'support': self.support}


class Material(BaseData):
    def __init__(self, idt: int, young: float):
        self.idt = idt
        self.young = young

    def __repr__(self):
        return f'Material(idt={self.idt}, young={self.young})'

    @classmethod
    def read_dict(cls, dct: dict) -> Material:
        return cls(**dct)

    def to_dict(self):
        return {'idt': self.idt,
                'young': self.young}


class Element(BaseData):
    def __init__(self, idt: int, nodes: list[Node], material: Material, area: float, layout_constraint):
        self.idt = idt
        self.nodes = nodes
        self.material = material
        self.area = area
        self.layout_constraint = layout_constraint

    def __repr__(self):
        return (f'Element(idt={self.idt}, nodes={[self.nodes[0].idt, self.nodes[1].idt]}, '
                f'material={self.material.idt}, area={self.area}, layout_constraint={self.layout_constraint})')

    def is_the_same(self, other: Element) -> bool:
        return (np.isclose(self.length(), other.length()) and (
                np.isclose(self.nodes[0].position[0], other.nodes[0].position[0]) and np.isclose(
            self.nodes[0].position[1], other.nodes[0].position[1])) and
                (np.isclose(self.nodes[1].position[0], other.nodes[1].position[0]) and
                 np.isclose(self.nodes[1].position[1], other.nodes[1].position[1])))

    def length(self) -> float:
        return np.linalg.norm(np.array(self.nodes[0].position) - np.array(self.nodes[1].position))

    @classmethod
    def read_dict(cls, dct: dict) -> Element:
        return cls(idt=dct['idt'],
                   nodes=[Node.read_dict(node) for node in dct['nodes']],
                   material=Material.read_dict(dct['material']),
                   area=dct['area'],
                   layout_constraint=dct['layout_constraint'])

    def to_dict(self):
        return {'idt': self.idt,
                'nodes': [node.idt for node in self.nodes],
                'material': self.material.idt,
                'area': self.area,
                'layout_constraint': self.layout_constraint}


class Structure(BaseData):
    def __init__(self, nodes: list[Node], elements: list[Element], materials: list[Material]):
        self.nodes = nodes
        self.elements = elements
        self.materials = materials

    @classmethod
    def read_dict(cls, dct: dict) -> type(BaseData):
        nodes = [Node.read_dict(node) for node in dct['nodes']]
        materials = [Material.read_dict(material) for material in dct['materials']]

        elements = []
        for el in dct['elements']:
            nodes_el = [node for node in nodes if node.idt in el['nodes']]
            material_el = materials[el['material'] - 1]
            elements.append(Element(idt=el['idt'],
                                    nodes=nodes_el,
                                    material=material_el,
                                    area=el['area'],
                                    layout_constraint=el['layout_constraint']))
        return cls(nodes=nodes, elements=elements, materials=materials)

    def to_dict(self):
        return {'nodes': [node.to_dict() for node in self.nodes],
                'elements': [element.to_dict() for element in self.elements],
                'materials': [material.to_dict() for material in self.materials]}
