import os
from data_handler import Modeller, SaveData, Optimizer, ComplianceMu, Material

# ================================ Defining case ================================
case = 4
<<<<<<< HEAD
only_read = False
=======
only_read = True
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
case_ref = 1  # DO NOT CHANGE THIS

# ================================ Create json file ================================
if not only_read:
    save_data = SaveData(step=1,
                         save_angles=False,
                         save_areas=False,
                         save_forces=False,
                         save_compliance=True,
                         save_move=False,
                         save_volume=False,
                         save_error=False)

    optimizer_data = Optimizer(compliance=ComplianceMu(beta=1e-1),
                               volume_max=1.0,
                               min_iterations=20,
                               max_iterations=15000,
                               use_adaptive_move=False,
                               initial_move_multiplier=1.0,
                               use_adaptive_damping=False,
                               initial_damping=0.7,
                               use_layout_constraint=False if case == 0 else True,
                               x_min=1e-12,
                               tolerance=1e-8)

    modeller = Modeller(filename=f'examples/hook/case_{case}.json',
                        data_to_save=save_data,
                        optimizer=optimizer_data)

    material = Material(1, 1e4)

    modeller.read_structure_from_dxf(elements_material=material, elements_area=1e-4)

    modeller.write_dxf()
    modeller.write_json()

    # ================================ Run Julia optimization ================================
    os.system(f'julia main.jl examples/hook/case_{case}.json')

# ================================ Read optimized structure ================================
markers_sizes = 0.7
markers_width = 3

modeller = Modeller.read(f'examples/hook/case_{case}.json')

# modeller.plot_initial_structure(default_width=0.5,
#                                 lc_width=3,
#                                 supports_markers_size=markers_sizes,
#                                 supports_markers_width=markers_width,
#                                 supports_markers_color='green',
#                                 forces_markers_size=markers_sizes,
#                                 forces_markers_width=markers_width,
#                                 forces_markers_color='magenta',
#                                 plot_loads=False,
#                                 plot_supports=False)
#
# modeller.plot_optimized_structure(cutoff=1e-4,
#                                   base_width=7,
#                                   supports_markers_size=markers_sizes,
#                                   supports_markers_width=markers_width,
#                                   supports_markers_color='green',
#                                   forces_markers_size=markers_sizes,
#                                   forces_markers_width=markers_width,
#                                   forces_markers_color='magenta',
#                                   plot_loads=False,
#                                   plot_supports=False)
#

<<<<<<< HEAD
# modeller.plot_dv_analysis(Modeller.read(f'examples/hook/case_{case_ref}.json'), width=1.1)
=======
modeller.plot_dv_analysis(Modeller.read(f'examples/hook/case_{case_ref}.json'), width=1.1)
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
# modeller.plot_dv_one_case(width=1.1)
