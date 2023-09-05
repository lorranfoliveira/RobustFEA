import sys
import pathlib

sys.path.append(str(pathlib.Path(__file__).parents[2]))

from data_handler import Modeller

modeller = Modeller.read('case_0.json')

modeller.save_mat_file()

markers_sizes = 0.7
markers_width = 3

modeller.plot_initial_structure(default_width=1,
                                lc_width=4,
                                supports_markers_size=markers_sizes,
                                supports_markers_width=markers_width,
                                supports_markers_color='green',
                                forces_markers_size=markers_sizes,
                                forces_markers_width=markers_width,
                                forces_markers_color='magenta')
#
# modeller.plot_optimized_structure(cutoff=1e-4,
#                                   base_width=10,
#                                   supports_markers_size=markers_sizes,
#                                   supports_markers_width=markers_width,
#                                   supports_markers_color='green',
#                                   forces_markers_size=markers_sizes,
#                                   forces_markers_width=markers_width,
#                                   forces_markers_color='magenta')

# modeller.plot_dv_analysis(Modeller.read('case_1.json'), width=1)
