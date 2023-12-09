import os
import sys
from data_handler import Modeller, SaveData, Optimizer, Material, CompliancePNorm

# ================================ Defining case ================================


#filename = files[0]
#filename = sys.argv[1]

def run(filename):
    use_layout_constraint = False
    optimize = True
    # ================================ Create json file ================================
    if optimize:
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



        modeller = Modeller(filename=filename,
                            data_to_save=save_data,
                            optimizer=optimizer_data)

        material = Material(1, 100000.0)

        modeller.read_structure_from_dxf(elements_material=material, elements_area=1e-5)

        # modeller.write_dxf()
        modeller.write_json()

        # ================================ Run Julia optimization ================================
        os.system(f'julia main.jl {modeller.filename}')

    # ================================ Read optimized structure ================================
    markers_sizes = 0.05
    markers_width = 2

    modeller = Modeller.read(f'{filename}')

    modeller.plot_initial_structure(default_width=0.5,
                                    lc_width=3,
                                    supports_markers_size=markers_sizes,
                                    supports_markers_width=markers_width,
                                    supports_markers_color='green',
                                    forces_markers_size=1,                                  forces_markers_color='gray',
                                    plot_loads=True,
                                    plot_supports=True)

    modeller.plot_optimized_structure(cutoff=1e-4,
                                    base_width=3,
                                    supports_markers_size=markers_sizes,
                                    supports_markers_width=markers_width,
                                    supports_markers_color='green',
                                    forces_markers_size=1,
                                    forces_markers_color='gray',
                                    plot_loads=True,
                                    plot_supports=True)

    #modeller.plot_compliance()

run('flower.json')