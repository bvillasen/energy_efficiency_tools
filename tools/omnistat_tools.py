import os, sys
import pandas

input_dir = '/mnt/c/Users/bvillase/work/benchmarks/cholla/frontier/energy_efficiency/frequency_sweep/maxsclk_1700'


omnistat_files = [ f for f in os.listdir(input_dir) if os.path.isfile(f'{input_dir}/{f}') and f.find('omnistat-') == 0 ]

file_name = 'omnistat-rocm.gpu.csv'
# for file_name in omnistat_files:
file_name = f'{input_dir}/{file_name}'
df = pandas.read_csv(file_name, header=[0, 1, 2], index_col=0)
columns = df.columns

  



