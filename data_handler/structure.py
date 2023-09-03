from __future__ import annotations
from .base_data import BaseData


class Node(BaseData):
    def __init__(self, idt: int, position: list[float], force: list[float], support: list[bool]):
        self.idt = idt
        self.position = position
        self.force = force
        self.support = support

    def __repr__(self):
        return f'Node(idt={self.idt}, position={self.position}, force={self.force}, support={self.support})'

    @classmethod
    def read_dict(cls, dct: dict) -> Node:
        return cls(**dct)


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
        elements = [Element.read_dict(element) for element in dct['elements']]
        materials = [Material.read_dict(material) for material in dct['materials']]
        return cls(nodes=nodes, elements=elements, materials=materials)

    def to_dict(self):
        return {'nodes': [node.to_dict() for node in self.nodes],
                'elements': [element.to_dict() for element in self.elements],
                'materials': [material.to_dict() for material in self.materials]}
