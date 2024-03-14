import ezdxf
import numpy as np

def generate_fan_example(b, n):
    if n%2 == 0:
        n += 1

    nodes = np.zeros((2*n + 1, 2))

    # Right node
    nodes[0] = [0.0, 0.0]

    for i, y in enumerate(np.linspace(-b/2, b/2, n)):
        nodes[i + 1] = [-b/2, y]

    for i, y in enumerate(np.linspace(-b/2, b/2, n)):
        nodes[n + i + 1] = [b/2, y]

    doc = ezdxf.new("R2010")
    msp = doc.modelspace()

    # Layers
    doc.layers.add(name="nodes_0.0_0.0_True_True", color=1)
    doc.layers.add(name="nodes_1.0_1.0_False_False", color=4)
    doc.layers.add(name="elements_default", color=2)

    # Nodes
    msp.add_point(nodes[0], dxfattribs={"layer": "nodes_1.0_1.0_False_False"})
    for node in nodes[1:]:
        msp.add_point(node, dxfattribs={"layer": "nodes_0.0_0.0_True_True"})
    
    # Elements
    for node in nodes[1:]:
        msp.add_line(nodes[0], node, dxfattribs={"layer": "elements_default"})

    doc.saveas("fan.dxf")


generate_fan_example(20, 5001)
