import os
from data_handler import Modeller, SaveData, Optimizer, ComplianceMu, Material, CompliancePNorm

# ================================ Defining case ================================
use_layout_constraint = False

# ================================ Create json file ================================
save_data = SaveData(step=1,
                        save_angles=False,
                        save_areas=False,
                        save_forces=False,
                        save_compliance=True,
                        save_move=False,
                        save_volume=False,
                        save_error=False)

optimizer_data = Optimizer(compliance=CompliancePNorm(p=30.0),
                            volume_max=1.0,
                            min_iterations=20,
                            max_iterations=15000,
                            use_adaptive_move=True,
                            initial_move_multiplier=1.0,
                            use_adaptive_damping=True,
                            initial_damping=0.0,
                            use_layout_constraint=use_layout_constraint,
                            x_min=1e-12,
                            tolerance=1e-8)

files = ['flower_025_1.json',
         'flower_05_1.json',
         'flower_075_1.json',
         'flower_1_1.json',
         'flower_1_075.json',
         'flower_1_05.json',
         'flower_1_025.json']

modeller = Modeller(filename=files[6],
                    data_to_save=save_data,
                    optimizer=optimizer_data)

material = Material(1, 1.0)

modeller.read_structure_from_dxf(elements_material=material, elements_area=1e-4)

# modeller.write_dxf()
modeller.write_json()

# ================================ Run Julia optimization ================================
os.system(f'julia main.jl {modeller.filename}')

# ================================ Read optimized structure ================================
markers_sizes = 0.7
markers_width = 3

modeller = Modeller.read(f'{modeller.filename}')

#modeller.plot_initial_structure(default_width=0.5,
                                #lc_width=3,
                                #supports_markers_size=markers_sizes,
                                #supports_markers_width=markers_width,
                                #supports_markers_color='green',
                                #forces_markers_size=markers_sizes,
                                #forces_markers_width=markers_width,
                                ##forces_markers_color='magenta',
                                #plot_loads=True,
                                #plot_supports=True)

modeller.plot_optimized_structure(cutoff=1e-4,
                                  base_width=7,
                                  supports_markers_size=markers_sizes,
                                  supports_markers_width=markers_width,
                                  supports_markers_color='green',
                                  forces_markers_size=markers_sizes,
                                  forces_markers_width=markers_width,
                                  forces_markers_color='magenta',
                                  plot_loads=False,
                                  plot_supports=False)

#modeller.plot_compliance()

