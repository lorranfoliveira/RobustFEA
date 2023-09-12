import os
import matplotlib.pyplot as plt
import numpy as np
from data_handler import Modeller, SaveData, Optimizer, ComplianceMu, Material

plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams['axes.labelsize'] = 20
plt.rcParams['xtick.labelsize'] = 15
plt.rcParams['ytick.labelsize'] = 17
plt.rcParams['legend.fontsize'] = 15

<<<<<<< HEAD
=======
case_1 = Modeller.read(f'examples/hook/case_1.json')
case_2 = Modeller.read(f'examples/hook/case_2.json')
case_3 = Modeller.read(f'examples/hook/case_3.json')
case_4 = Modeller.read(f'examples/hook/case_4.json')

>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c

def plot_histogram(*cases):
    fig, ax = plt.subplots()
    ax.set_xlabel('Normalized cross-sectional area')
    ax.set_ylabel('Number of elements')
    ax.set_xticks(np.linspace(0.105, 0.9, 5),
                  ['(0 - 0.2)', '(0.2 - 0.4)', '(0.4 - 0.6)', '(0.6 - 0.8)', '(0.8 - 1.0)'])

    areas = []
    labels = []
    colors = []

    for i, case in enumerate(cases):
        used_areas = [a for a in case.last_iteration_norm_areas() if a > 1e-4]
        areas.append(used_areas)
        labels.append(f'Case {i + 1}')
        colors.append(plt.cm.tab20(i))

        # areas = np.array(areas).T

    ax.hist(areas, bins=5, label=labels, color=colors)

    ax.legend()
    plt.show()


def plot_lc_by_bars_number(*cases):
    # Create bar plot
    fig, ax = plt.subplots(1, len(cases))

    for i, case in enumerate(cases):
        case_title = f'LC {i + 1}'
        lcs = case.get_restricted_elements()
        values = [len(lcs[lc]) for lc in lcs]
        labels = [f'{i + 1}' for i in range(len(values))]
        colors = [plt.cm.tab20(i) for i in range(len(values))]

        ax[i].bar(labels, values, label=case_title, color=colors)
        ax[i].set_xlabel('Layout constraint')
        ax[i].set_ylabel('Number of elements')

        ax[i].set_title(f'Case {i + 1}')

    fig.tight_layout()
    plt.show()

<<<<<<< HEAD

=======
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
def plot_number_of_restricted_bars(*cases):
    fig, ax = plt.subplots()

    points = []
    labels = []

    for i, case in enumerate(cases):
        lcs = case.get_restricted_elements()
        value = sum([len(lcs[lc]) for lc in lcs])

        points.append([i + 1, value])
        labels.append(f'LC {i + 1}')

    points = np.array(points)

    # Points
<<<<<<< HEAD
    ax.plot(points[:, 0], points[:, 1], '-o', markersize=10, linewidth=1.7, color=plt.cm.tab20c(1),
            markerfacecolor=plt.cm.tab20(0))
=======
    ax.vlines(points[:, 0], 0, points[:, 1], color=plt.cm.tab20c(1), linewidth=1, linestyle='--')
    ax.hlines(points[:, 1], 0, points[:, 0], color=plt.cm.tab20c(1), linewidth=1, linestyle='--')
    ax.plot(points[:, 0], points[:, 1], '-o', markersize=10, linewidth=1.7, color=plt.cm.tab20c(1), markerfacecolor=plt.cm.tab20(0))
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
    ax.set_ylabel('Number of restricted elements')
    ax.set_xticks(points[:, 0].astype(int), [f'Case {i}' for i in points[:, 0].astype(int)])
    ax.set_yticks(points[:, 1])
    plt.xlim(0.7, 4.2)
    plt.ylim(0, 400)

    plt.show()

<<<<<<< HEAD

def plot_compliances(*cases):
    fig, ax1 = plt.subplots()

    points_ax1 = []

    for i, case in enumerate(cases):
        points_ax1.append([i + 1, case.last_iteration.iteration.compliance])

    points_ax1 = np.array(points_ax1)
    color1 = plt.cm.tab20c(8)
    ax1.plot(points_ax1[:, 0], points_ax1[:, 1], '-o', markersize=10, linewidth=1.7, color=plt.cm.tab20c(9),
             markerfacecolor=color1)
    ax1.set_xticks(points_ax1[:, 0].astype(int), [f'Case {i}' for i in points_ax1[:, 0].astype(int)])
    ax1.set_yticks([float(f'{i:.2f}') for i in points_ax1[:, 1]])
    ax1.set_ylabel('Compliance', color=color1)
    ax1.tick_params(axis='y', labelcolor=color1)

    ax2 = ax1.twinx()

    points_ax2 = []
    color2 = plt.cm.tab20c(0)

    for i, case in enumerate(cases):
        lcs = case.get_restricted_elements()
        value = sum([len(lcs[lc]) for lc in lcs])

        points_ax2.append([i + 1, value])

    points_ax2 = np.array(points_ax2)

    # Points
    ax2.plot(points_ax2[:, 0], points_ax2[:, 1], '-o', markersize=10, linewidth=1.7, color=plt.cm.tab20c(1),
             markerfacecolor=color2)
    ax2.set_ylabel('Number of restricted elements', color=color2)
    ax2.set_yticks(points_ax2[:, 1])
    ax2.tick_params(axis='y', labelcolor=color2)

    plt.show()


=======
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
def plot_number_of_lcs(*cases):
    fig, ax = plt.subplots()

    points = []
    labels = []

    for i, case in enumerate(cases):
        value = len(case.get_restricted_elements())

        points.append([i + 1, value])
        labels.append(f'LC {i + 1}')

    points = np.array(points)

    # Points
    ax.vlines(points[:, 0], 0, points[:, 1], color=plt.cm.tab20c(5), linewidth=1, linestyle='--')
    ax.hlines(points[:, 1], 0, points[:, 0], color=plt.cm.tab20c(5), linewidth=1, linestyle='--')
<<<<<<< HEAD
    ax.plot(points[:, 0], points[:, 1], '-o', markersize=10, linewidth=1.7, color=plt.cm.tab20c(5),
            markerfacecolor=plt.cm.tab20c(4))
=======
    ax.plot(points[:, 0], points[:, 1], '-o', markersize=10, linewidth=1.7, color=plt.cm.tab20c(5), markerfacecolor=plt.cm.tab20c(4))
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
    ax.set_ylabel('Number of layout constraints')
    ax.set_xticks(points[:, 0].astype(int), [f'Case {i}' for i in points[:, 0].astype(int)])
    ax.set_yticks(points[:, 1])
    plt.xlim(0.7, 4.2)
    plt.ylim(0, 20)

    plt.show()

<<<<<<< HEAD

cases = [Modeller.read(f'examples/hook/case_{i + 1}.json') for i in range(4)]
# plot_number_of_lcs(*cases)
# plot_number_of_restricted_bars(*cases)
plot_compliances(*cases)
# save_means_and_sdts(*cases)
# plot_histogram(*cases)
=======
def save_means_and_sdts(*cases):
    with open('means_and_sdts.txt', 'w') as f:
        for i, case in enumerate(cases):
            used_areas = [a for a in case.last_iteration_norm_areas() if a > 1e-4]
            f.write(f'Case {i + 1}: mean = {np.mean(used_areas)}, std = {np.std(used_areas)}\n')

cases = [case_1, case_2, case_3, case_4]
plot_number_of_lcs(*cases)
plot_number_of_restricted_bars(*cases)
save_means_and_sdts(*cases)
plot_histogram(*cases)
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
# plot_lc_by_bars_number(case_1, case_2, case_3, case_4)
