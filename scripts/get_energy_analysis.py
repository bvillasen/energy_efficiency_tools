import sys, os
import numpy
import argparse
import numpy as np

# Add the tools directory
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, parent_dir)
import tools.analysis_tools as tools

parser = argparse.ArgumentParser( description="Plot power profile.")
parser.add_argument('--input_dir', dest='input_dir', type=str, help='Input directory where stats and counters dirs are located', default=None )
parser.add_argument('--edp_alpha', dest='edp_alpha', type=float, help='EDP alpha value', default=1.0 )
parser.add_argument('--edp_beta', dest='edp_beta', type=float, help='EDP beta value', default=1.0 )
args = parser.parse_args()

if args.input_dir is None:
  print("ERROR: You need to pass the path to the directory containing the rocprof output")
  sys.exit(1)

input_dir = args.input_dir
edp_alpha = args.edp_alpha
edp_beta = args.edp_beta
print( f'Input directory: {input_dir}')
print( f'EDP alpha: {edp_alpha}')
print( f'EDP beta: {edp_beta}')

maxsclk_dirs = [ d for d in os.listdir(input_dir) if os.path.isdir(f'{input_dir}/{d}') and d.find('maxsclk') >= 0 ]
maxsclk_vals = [ int(d.split('_')[1]) for d in maxsclk_dirs ]
maxsclk_vals.sort()

data = {}
for run_indx, maxsclk in enumerate(maxsclk_vals):
  print(f'\nLoading data for maxsclk: {maxsclk}')
  data[run_indx] = { 'maxsclk':maxsclk }
  run_dir = f'{input_dir}/maxsclk_{maxsclk}'
  simulation_time = tools.get_runtime(run_dir)
  data[run_indx]['time'] = simulation_time
  energy_data = tools.load_energy_counters(run_dir)
  data[run_indx]['energy'] = energy_data


figure_name = f'{input_dir}/time_energy_vs_freq.png'
tools.plot_energy_analysis( data, edp_alpha, edp_beta, figure_name )