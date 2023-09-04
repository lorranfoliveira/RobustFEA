from data_handler import Modeller, SaveData, Optimizer, ComplianceMu, Material

# save_data = SaveData(step=1,
#                      save_angles=False,
#                      save_areas=False,
#                      save_forces=False,
#                      save_compliance=True,
#                      save_move=False,
#                      save_volume=False,
#                      save_error=False)
#
# optimizer_data = Optimizer(compliance=ComplianceMu(beta=1e-1),
#                            volume_max=1.0,
#                            min_iterations=20,
#                            max_iterations=15000,
#                            use_adaptive_move=False,
#                            initial_move_multiplier=1.0,
#                            use_adaptive_damping=False,
#                            initial_damping=0.0,
#                            use_layout_constraint=True,
#                            x_min=1e-12,
#                            tolerance=1e-8)
#
# modeller = Modeller(filename='mesh_example.json',
#                     data_to_save=save_data,
#                     optimizer=optimizer_data)
#
# material = Material(1, 1.0)
# modeller.read_structure_from_dxf(material)

# modeller.write_dxf()
# modeller.write_json()

modeller = Modeller.read('mesh_example.json')

modeller.plot_initial_structure(default_width=1,
                                lc_width=4,
                                supports_markers_size=0.05,
                                supports_markers_width=4,
                                supports_markers_color='green',
                                forces_markers_size=0.05,
                                forces_markers_width=4,
                                forces_markers_color='magenta')

modeller.plot_optimized_structure(cutoff=1e-4,
                                  base_width=10,
                                  supports_markers_size=0.05,
                                  supports_markers_width=4,
                                  supports_markers_color='green',
                                  forces_markers_size=0.05,
                                  forces_markers_width=4,
                                  forces_markers_color='magenta')
