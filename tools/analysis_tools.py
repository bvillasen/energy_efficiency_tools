
import sys, os
import numpy as np



def plot_energy_analysis( data, edp_alpha, edp_beta, figure_name ):

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

  sclk_vals, time_vals, energy_vals = [], [], []
  for indx in data:
    data_freq = data[indx]
    sclk_vals.append( data_freq['maxsclk'] )
    time_vals.append( data_freq['time'] )
    energy_vals.append( data_freq['energy']['total'] /3.6e6 ) # convert from joules to kWh
  sclk_vals = np.array(sclk_vals)
  energy_vals = np.array(energy_vals)
  time_vals = np.array(time_vals)

  ax = ax_l[0]
  ax.scatter(sclk_vals, time_vals)
  ax.plot(sclk_vals, time_vals, ls='--', lw=line_width)
  ax.set_ylabel( 'Simulation time [secs]', fontsize=fs_labels, labelpad=0 )
  ax.grid( color='gray', alpha=0.3)
  [sp.set_linewidth(border_width) for sp in ax.spines.values()]

  ax = ax_l[1]
  ax.scatter(sclk_vals, energy_vals)
  ax.plot(sclk_vals, energy_vals, ls='--', lw=line_width )
  ax.set_ylabel( 'Energy used [kWh]', fontsize=fs_labels, labelpad=0 )
  ax.grid( color='gray', alpha=0.3)
  [sp.set_linewidth(border_width) for sp in ax.spines.values()]

  ax = ax_l[2]
  edp_vals = energy_vals**edp_alpha * time_vals**edp_beta
  ax.scatter(sclk_vals, edp_vals)
  ax.plot(sclk_vals, edp_vals, ls='--', lw=line_width )
  edp_text = fr"$EDP = E^\alpha  t^\beta \,\,\, [\alpha={edp_alpha}  ,  \beta={edp_beta}]$" 
  ax.set_ylabel( edp_text , fontsize=fs_labels, labelpad=0 )
  ax.grid( color='gray', alpha=0.3)
  [sp.set_linewidth(border_width) for sp in ax.spines.values()]
  ax.set_xlabel( 'GPU Frequency cap [MHz]', fontsize=fs_labels, labelpad=0 )

  fig.align_labels()
  fig.savefig( f'{figure_name}', bbox_inches='tight', dpi=300, facecolor=fig.get_facecolor() )
  print( f'Saved Figure: {figure_name}' )


def parse_energy_counter_file( file_name ):
  f = open( file_name, 'r')
  line = f.readlines()[0].split(' ')
  E = float(line[0]) #Joules
  t = float(line[2]) /1e6  #secs
  f.close()
  return {'E':E, 't':t}

def load_energy_counters(run_dir):
  energy_files = [f for f in os.listdir(run_dir) if f.find('energy') >=0 and f.find('node') > 0 ]
  energy_start_files = [ f for f in energy_files if f.find('start') > 0 ]
  energy_end_files = [ f for f in energy_files if f.find('end') > 0 ]
  nodes_start = [int(f.split('_')[3].replace('.txt','')) for f in energy_start_files ]
  nodes_end = [int(f.split('_')[3].replace('.txt','')) for f in energy_end_files ]
  energy_nodes = []
  for node_id in nodes_start:
    if node_id in nodes_end: energy_nodes.append(node_id)
    else:
      print( f"ERROR: energy_end counter file not found for node_id: {node_id}")
  print(f'Parsing energy counter files for nodes: {energy_nodes}')
  energy_data = {'node_ids':energy_nodes, 'nodes':{}}
  energy_total = 0
  for node_id in energy_nodes:    
    start_file = f'{run_dir}/energy_start_node_{node_id}.txt'
    end_file = f'{run_dir}/energy_end_node_{node_id}.txt'
    energy_start = parse_energy_counter_file( start_file )
    energy_end = parse_energy_counter_file( end_file )
    delta_energy = energy_end['E'] - energy_start['E'] #joules
    delta_time = energy_end['t'] - energy_start['t']   #seconds
    energy_total += delta_energy
    energy_data['nodes'][node_id] = {'energy':delta_energy, 'time':delta_time }
  energy_data['total'] = energy_total
  print(f"Energy: {energy_total/3.6e6:.2e}  kWh") 
  return energy_data

def get_runtime(run_dir):
  start_file = f'{run_dir}/time_start.txt'
  end_file = f'{run_dir}/time_end.txt'
  start_time = parse_time( start_file )
  end_time = parse_time( end_file )
  delta_time = end_time - start_time #seconds
  return delta_time

def parse_time( time_file ):
  from dateutil.tz import gettz
  from dateutil import parser
  date_str = open( time_file, 'r').read()[:-1]
  # Define tzinfos to map 'EDT' to US Eastern Time
  # tzinfos = {"EDT": gettz("America/New_York")}
  # dt = parser.parse(date_str, tzinfos=tzinfos)
  dt = parser.parse(date_str)
  seconds = dt.timestamp()
  return seconds  

