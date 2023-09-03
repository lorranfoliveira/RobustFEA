from data_handler import Modeller, SaveData, Optimizer, ComplianceMu, Material

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
                           initial_damping=0.0,
                           use_layout_constraint=True,
                           x_min=1e-12,
                           tolerance=1e-8)

modeller = Modeller(filename='mesh_example.json',
                    data_to_save=save_data,
                    optimizer=optimizer_data)

material = Material(1, 1)
modeller.read_structure_from_dxf(material)

modeller.write_dxf()
