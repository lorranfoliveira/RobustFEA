from data_handler import Modeller

modeller = Modeller.read('example_1.json')

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
