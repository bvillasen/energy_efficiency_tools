import sys, os
import numpy
import argparse
import numpy as np

# Add the tools directory
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, parent_dir)
import tools.analysis_tools as tools

import importlib
importlib.reload(tools)



parser = argparse.ArgumentParser( description="Plot power profile.")
parser.add_argument('--input_dir', dest='input_dir', type=str, help='Input directory where stats and counters dirs are located', default=None, nargs='+' )
parser.add_argument('--edp_alpha', dest='edp_alpha', type=float, help='EDP alpha value', default=1.0 )
parser.add_argument('--edp_beta', dest='edp_beta', type=float, help='EDP beta value', default=1.0 )
args = parser.parse_args()

if args.input_dir is None:
  print("ERROR: You need to pass the path to the directory containing the rocprof output")
  sys.exit(1)


input_dirs = args.input_dir
edp_alpha = args.edp_alpha
edp_beta = args.edp_beta
print( f'Input directory: {input_dirs}')
print( f'EDP alpha: {edp_alpha}')
print( f'EDP beta: {edp_beta}')


frequency_sweep_data_all = {}

for indx,input_dir in enumerate(input_dirs):

  job_data = tools.load_job_output_file( input_dir ) 
  
  if 'frequency_sweep' in job_data:
    frequency_sweep_data = tools.load_frequency_sweep_data( input_dir )

    # Generate the time, energy, and EDP vs frequency cap plots
    figure_name = f'{input_dir}/time_energy_vs_frequency_cap.png'
    # title = '   Cholla hydrodynamics - Single Frontier node run'
    title = None
    tools.plot_frequency_cap_energy_analysis( job_data, edp_alpha, edp_beta, figure_name, title=title )

    frequency_sweep_data_all[indx] = {'job_data': job_data, 'frequency_sweep_data':frequency_sweep_data }


figure_name = f'frequency_sweep_combined.png'
# title = '   Cholla hydrodynamics - Weak scaling on Frontier'
title = None
tools.plot_frequency_cap_energy_analysis(frequency_sweep_data_all, edp_alpha, edp_beta, figure_name, multiple_data=True, title=title )