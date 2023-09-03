import numpy as np
import json


def npz_to_json_file(json_file):
    with open(json_file, 'r') as file:
        json_data = json.load(file)

    supports = np.loadtxt('SUPP.txt')[:, 0].astype(int).tolist()
    loads = np.loadtxt('LOAD.txt')[:, 0].astype(int).tolist()
    points = np.loadtxt('NODE.txt')
    elements = np.loadtxt('BARS.txt').astype(int)

    json_data['input_structure']['nodes'] = []
    json_data['input_structure']['elements'] = []

    for i, point in enumerate(points):
        node_data = {'id': i + 1,
                     'position': [point[0], point[1]],
                     'support': [False, False],
                     'force': [0.0, 0.0], }
        json_data['input_structure']['nodes'].append(node_data)

    for i, element in enumerate(elements):
        element_data = {'id': i + 1,
                        'nodes': [int(element[0]), int(element[1])],
                        'area': 1.0,
                        'material': 1,
                        'layout_constraint': 0}
        json_data['input_structure']['elements'].append(element_data)

    for sup in supports:
        json_data['input_structure']['nodes'][sup - 1]['support'] = [True, True]

    Fy = 1 / 25
    Fx = Fy / 4
    for load in loads:
        json_data['input_structure']['nodes'][load - 1]['force'] = [Fx, Fy]

    data_lc = np.load(f'{json_file.replace(".json", ".npz")}')['arr_4']

    for i, lc in enumerate(data_lc):
        for j in lc:
            if j > -1:
                json_data['input_structure']['elements'][j]['layout_constraint'] = i + 1

    with open(json_file, 'w') as file:
        json.dump(json_data, file)


npz_to_json_file('hook_8.json')
