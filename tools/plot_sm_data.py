import os, sys
import numpy as np
import argparse

# Add the tools directory
sm_tools_dir = os.path.abspath('/mnt/c/Users/bvillase/work/util/system_monitor/tools')
sys.path.insert(0, sm_tools_dir)
import sm_tools
import analysis_tools as tools

parser = argparse.ArgumentParser( description="Plot power profile.")
parser.add_argument('--input_dir', dest='input_dir', type=str, help='Input directory where stats and counters dirs are located', default=None )
args = parser.parse_args()

# if args.input_dir is None:
#   print("ERROR: You need to pass the path to the directory containing the rocprof output")
#   sys.exit(1)

# input_dir = args.input_dir
# input_dir = '/mnt/c/Users/bvillase/work/benchmarks/cholla/frontier/energy_efficiency/frequency_sweep_system_monitor'
input_dir = '/mnt/c/Users/bvillase/work/benchmarks/rocHPL/frontier/energy_efficiency/frequency_sweep_system_monitor'
print( f'Input directory: {input_dir}')

# Find the frequency cap values in the input directory
maxsclk_dirs = [ d for d in os.listdir(input_dir) if os.path.isdir(f'{input_dir}/{d}') and d.find('maxsclk') >= 0 ]
maxsclk_vals = [ int(d.split('_')[1]) for d in maxsclk_dirs ]
maxsclk_vals.sort()

maxsclk_vals = [ 1700, 1400, 1100, 800 ]

# maxsclk_vals = [ 1700 ]

# Load the energy and timing data for each run in in the sweep
data = {}
for run_indx, maxsclk in enumerate(maxsclk_vals):
  print(f'\nLoading data for maxsclk: {maxsclk}')
  data[run_indx] = { 'maxsclk':maxsclk }
  run_dir = f'{input_dir}/maxsclk_{maxsclk}'
  simulation_time = tools.get_runtime(run_dir)
  data[run_indx]['time'] = simulation_time
  energy_data = tools.load_energy_counters(run_dir)
  data[run_indx]['energy'] = energy_data
  sm_file = f'{run_dir}/system_monitor_node_0.txt'
  sm_data_raw, sm_data = sm_tools.load_system_monitor_file( sm_file )
  data[run_indx]['sm_data'] = sm_data


figure_name = f'{input_dir}/freq_vs_sclk_cap.png' 
time_interval = [50, 52]

device_id = 0

import matplotlib.pyplot as plt
nrows, ncols = 3, 1
figure_width = 12
h_scale_factor = 0.3
figure_height = figure_width * h_scale_factor * nrows
fig, ax_l = plt.subplots(nrows=nrows, ncols=ncols, figsize=(figure_width,figure_height))
plt.subplots_adjust( hspace = 0.03, wspace=0.)

# Font sizes
fs_legend = 7
fs_labels = 10

line_width = 1.2
border_width = 1.4

for run_indx in data:
  data_run = data[run_indx]
  maxsclk = data_run['maxsclk']
  data_device = data_run['sm_data'][device_id]
  power = data_device['power']
  sclk = data_device['sclk']
  gfx_freq = data_device['avr_gfxclk']
  time = data_device['time_microsecs'] / 1e6

  label = f'{maxsclk} MHz'

  data_to_plot = [power, sclk, gfx_freq]
  ylables = ['Power [W]', 'Target freq [MHz]', 'GFX Freq [MHz]']

  for i in range(3):
    ax = ax_l[i]
    ax.plot(time, data_to_plot[i], label=label)

    box = ax.get_position()
    ax.set_position([box.x0, box.y0, box.width * 0.9, box.height])
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5), fontsize=fs_legend)

    ax.set_ylabel( ylables[i], fontsize=fs_labels, labelpad=0 )

    ax.grid( color='gray', alpha=0.3)
    [sp.set_linewidth(border_width) for sp in ax.spines.values()]

    
    if i<2: ax.set_xticklabels([])

    # if i == 0: ax.set_ylim(300, 600)
    # ax.set_xlim(time_interval[0], time_interval[1])

  
ax.set_xlabel( 'Time [secs]', fontsize=fs_labels, labelpad=0 )
fig.align_labels()

fig.align_labels()
fig.savefig( f'{figure_name}', bbox_inches='tight', dpi=300, facecolor=fig.get_facecolor() )
print( f'Saved Figure: {figure_name}' )


