import ezdxf
import numpy as np

def xy_circle(radius, n)->np.array:

    # Number of elements in each side
    # Must be odd
    if n%2 == 0:
        raise ValueError("n must be odd")
    
    thetas1 = np.linspace(-np.pi/4, np.pi/4, n)
    thetas2 =  np.linspace(5*np.pi/4, 3*np.pi/4, n)
    # Concatenate thetas
    thetas = np.concatenate([thetas1, thetas2])

    x = radius*np.cos(thetas)
    y = radius*np.sin(thetas)

    return np.array([x, y]).T

def generate_fan_example(radius, n):
    nodes = xy_circle(radius, n)

    doc = ezdxf.new("R2010")
    msp = doc.modelspace()

    # Layers
    doc.layers.add(name="nodes_0.0_0.0_True_True", color=1)
    doc.layers.add(name="nodes_1.0_1.0_False_False", color=4)
    doc.layers.add(name="elements_default", color=2)

    # Nodes
    center = np.array([0,0])
    msp.add_point(center, dxfattribs={"layer": "nodes_1.0_1.0_False_False"})
    for node in nodes:
        msp.add_point(node, dxfattribs={"layer": "nodes_0.0_0.0_True_True"})
    
    # Elements
    for node in nodes:
        msp.add_line(center, node, dxfattribs={"layer": "elements_default"})

    doc.saveas("fan_circle.dxf")

generate_fan_example(5, 31)
