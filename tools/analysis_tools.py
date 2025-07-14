
import sys, os
import numpy as np



def plot_frequency_cap_energy_analysis( job_data, edp_alpha, edp_beta, figure_name, multiple_data=False, title=None ):

  data_all = job_data
  if not multiple_data: data_all = {0:{'job_data':data_all}} 

  import matplotlib.pyplot as plt
  nrows, ncols = 3, 1
  figure_width = 12
  h_scale_factor = 0.3
  figure_height = figure_width * h_scale_factor * nrows
  fig, ax_l = plt.subplots(nrows=nrows, ncols=ncols, figsize=(figure_width,figure_height))
  plt.subplots_adjust( hspace = 0.05, wspace=0.)

  # Font sizes
  fs_legend = 12
  fs_title = 14
  fs_labels = 12
  label_pad = 4

  line_width = 1.2
  border_width = 1.4


  for indx in data_all:

    n_nodes = data_all[indx]['job_data']['n_nodes']
    data = data_all[indx]['job_data']['frequency_sweep']
    # print(data)

    sclk_vals, time_vals, energy_vals = [], [], []
    for indx in data:
      data_freq = data[indx]
      sclk_vals.append( data_freq['frequency_cap'] )
      time_vals.append( data_freq['duration_secs'] )
      energy_vals.append( data_freq['energy_kwh'] ) 
    sclk_vals = np.array(sclk_vals)
    energy_vals = np.array(energy_vals) / n_nodes
    energy_joules = np.array(energy_vals) * 3.6e6
    time_vals = np.array(time_vals)
    edp_vals = energy_joules**edp_alpha * time_vals**edp_beta

    label = f'N nodes: {n_nodes}'
    ax = ax_l[0]
    ax.scatter(sclk_vals, time_vals, label=label)
    ax.plot(sclk_vals, time_vals, ls='--', lw=line_width)
    
    ax = ax_l[1]
    ax.scatter(sclk_vals, energy_vals)
    ax.plot(sclk_vals, energy_vals, ls='--', lw=line_width )
    
    ax = ax_l[2]
    ax.scatter(sclk_vals, edp_vals)
    ax.plot(sclk_vals, edp_vals, ls='--', lw=line_width )
    
  
  ax = ax_l[0]
  ax.legend(frameon=False, fontsize=fs_legend)
  ax.set_ylabel( 'Execution time [secs]', fontsize=fs_labels, labelpad=label_pad )
  ax.grid( color='gray', alpha=0.4)
  [sp.set_linewidth(border_width) for sp in ax.spines.values()]
  ax.set_xticklabels([])
  if title is not None: ax.set_title(title, loc='left', x=0.0, fontsize=fs_title)
  
  ax = ax_l[1]
  ax.set_ylabel( 'Energy per node [kWh]', fontsize=fs_labels, labelpad=label_pad )
  # ax.set_ylabel( 'Energy  [kWh]', fontsize=fs_labels, labelpad=2 )
  ax.grid( color='gray', alpha=0.4)
  [sp.set_linewidth(border_width) for sp in ax.spines.values()]
  ax.set_xticklabels([])

  ax = ax_l[2]
  edp_text = fr"$EDP = E^\alpha  t^\beta \,\,\, [\alpha={edp_alpha}  ,  \beta={edp_beta}]$" 
  ax.set_ylabel( edp_text , fontsize=fs_labels, labelpad=label_pad)
  ax.grid( color='gray', alpha=0.4)
  [sp.set_linewidth(border_width) for sp in ax.spines.values()]

  ax.set_xlabel( 'GPU Frequency cap [MHz]', fontsize=fs_labels, labelpad=5 )



  fig.align_labels()
  fig.savefig( f'{figure_name}', bbox_inches='tight', dpi=300, facecolor=fig.get_facecolor() )
  print( f'Saved Figure: {figure_name}' )

def load_job_output_file( input_dir, file_name='job_output.log' ):
  job_output_file = f'{input_dir}/{file_name}'
  print( f'Loading file: {job_output_file}')
  file = open( job_output_file, 'r' )
  lines = file.readlines()

  job_data = { }
  run_index = 0
  for line in lines:
    if line.find('N_NODES:') == 0: job_data['n_nodes'] = int(line.split(' ')[1])
    if line.find('###### Starting run with frequency cap:') == 0: 
      if 'frequency_sweep' not in job_data: 
        job_data['frequency_sweep'] = {}
        job_data['frequency_cap_vals'] = [] 
      line = line.replace('###### Starting run with frequency cap: ', '')
      frequency_cap = float( line.split(' ')[0] )
      print( f'Loading data for frequency_cap: {frequency_cap}')
      job_data['frequency_cap_vals'].append( frequency_cap ) 
      run_data = {'frequency_cap': frequency_cap }
    if line.find('--> Duration ') >= 0: run_data['duration_secs'] = int((line.split('= ')[1]).split(' ')[0])
    if line.find('Approximate Total Node Energy Consumed') >=0 :
      run_data['energy_kwh'] = float((line.split('= ')[1]).split(' ')[0])
      print( f" duration: {run_data['duration_secs']}  secs    energy: {run_data['energy_kwh']}  KWh")
    if line.find('WARNING') >= 0: print(line)
    if line.find('###### Finished run with frequency cap:') == 0: 
      job_data['frequency_sweep'][run_index] = run_data
      run_index += 1

  return job_data

def load_frequency_sweep_data( input_dir ):
  # Find the frequency cap values in the input directory
  maxsclk_dirs = [ d for d in os.listdir(input_dir) if os.path.isdir(f'{input_dir}/{d}') and d.find('maxsclk') >= 0 ]
  maxsclk_vals = [ int(d.split('_')[1]) for d in maxsclk_dirs ]
  maxsclk_vals.sort()

  # Load the energy and timing data for each run in in the sweep
  data = {}
  for run_indx, maxsclk in enumerate(maxsclk_vals):
    # print(f'Loading data for maxsclk: {maxsclk}')
    data[run_indx] = { 'frequency_cap':maxsclk }
    run_dir = f'{input_dir}/maxsclk_{maxsclk}'
    simulation_time = get_runtime(run_dir)
    data[run_indx]['duration_secs'] = simulation_time
    energy_data = load_energy_counters(run_dir)
    data[run_indx]['energy'] = energy_data
    data[run_indx]['energy_kwh'] = energy_data['total'] / 3.6e6   
  return data

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
  # print(f'Parsing energy counter files for nodes: {energy_nodes}')
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
  # print(f"Energy: {energy_total/3.6e6:.2e}  kWh") 
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

