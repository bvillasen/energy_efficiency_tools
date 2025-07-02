#!/bin/bash
#SBATCH -A ven114
#SBATCH -J freq_sweep
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH -e job_error.log
#SBATCH -o job_output.log
#SBATCH -q debug

#### Global parameters
EE_TOOLS_PATH=${HOME}/util/energy_efficiency_tools
DEVICE_IDS=(0 1 2 3 4 5 6 7)
MAX_SCLK_VALS=(1700 1600 1500 1400 1300 1200 1100 1000 900 800 700)
# MAX_SCLK_VALS=(1700 1400 1100 800)
# MAX_SCLK_VALS=(1700)
export USE_OMNISTAT=0
export USE_SYSTEM_MONITOR=1


#### Job parameters
WORK_DIR=$PWD
N_MPI=8
# Cholla
# EXEC="${HOME}/code/cholla/bin/cholla.hydro.frontier parameter_file.txt"
# AFFINITY="-c 7 --gpu-bind=closest"  

# #### Setup application environment
# SYSTEM=frontier source ${HOME}/code/cholla/scripts/set_env.sh


# rocHPL
module purge
module load PrgEnv-gnu
module load rocm/6.2.4
module load gcc
module load craype-accel-amd-gfx90a
export MPICH_GPU_SUPPORT_ENABLED=1
HPL_P=2
HPL_Q=4
HPL_N=256000
HPL_NB=512             
HPL_p=2
HPL_q=4
HPL_f=0.3
N_ITER=1 
EXEC="${HOME}/code/energy_efficiency/apps/rocHPL/code/rocHPL/build/run_rochpl -P ${HPL_P} -Q ${HPL_Q} -p ${HPL_p} -q ${HPL_q} -N ${HPL_N} --NB ${HPL_NB} -f ${HPL_f} --it ${N_ITER}"
AFFINITY="-c 7 --cpu-bind=cores --threads-per-core=1 --gpus-per-task 1 --gpu-bind=closest"


if [ ${USE_OMNISTAT} -eq 1 ]; then
  #### Setup omnistat
  export OMNISTAT_VICTORIA_DATADIR=/tmp/omnistat/${SLURM_JOB_ID}
  ml use /autofs/nccs-svm1_sw/crusher/amdsw/modules
  ml omnistat-wrapper
fi

if [ ${USE_SYSTEM_MONITOR} -eq 1 ]; then
  ### Setup system_monitor
  export SYSTEM_MONITOR_ROOT=${HOME}/util/system_monitor
  export SYSTEM_MONITOR_TIME=400
  export SYSTEM_MONITOR_FREQ=1000
  export SYSTEM_MONITOR_CORE=2  
fi

#### Run the frequency sweep job
echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"

# Loop over the frequency caps 
for MAX_SCLK in "${MAX_SCLK_VALS[@]}"
do

  # Setup directory for this MAX_SCLK
  RUN_DIR=${WORK_DIR}/maxsclk_${MAX_SCLK}
  if [ ! -d "${RUN_DIR}" ]; then
    mkdir -p ${RUN_DIR}
  fi

  # Setup directory for energy counters
  export ENERGY_COUNTER_DIR=${RUN_DIR}

  # Setup directory for energy counters
  export SYSTEM_MONITOR_DIR=${RUN_DIR}

  # Set the frequency cap on all devices on the node
  for DEVICE_ID in "${DEVICE_IDS[@]}"
  do
    set_freq_cmnd="/usr/bin/set_gpu_max_sclk -g ${DEVICE_ID} ${MAX_SCLK}"
    echo -e "${set_freq_cmnd} "
    eval ${set_freq_cmnd} 
  done

  # Print the SCLK range
  rocm-smi --showsclkrange

if [ ${USE_OMNISTAT} -eq 1 ]; then
  # Start Omnistat (0.001 second sampling rate)
  ${OMNISTAT_WRAPPER} usermode --start --interval 0.01
fi

  # Run the application
  echo "Starting application. $(date)"
  echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_start.txt
  srun -n $N_MPI $AFFINITY ${EE_TOOLS_PATH}/tools/app_launcher.sh  $EXEC > ${RUN_DIR}/app_output.txt
  echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_end.txt
  echo "Finished application. $(date)"

if [ ${USE_OMNISTAT} -eq 1 ]; then
  # Finish Omnistat, generate summary pdf and copy database
  ${OMNISTAT_WRAPPER} usermode --stopexporters
  ${OMNISTAT_WRAPPER} query --interval 0.01 --job ${SLURM_JOB_ID} --pdf ${RUN_DIR}/omnistat.${SLURM_JOB_ID}.pdf
  ${OMNISTAT_WRAPPER} usermode --stopserver
  mv /tmp/omnistat/${SLURM_JOB_ID} ${RUN_DIR}/data_omnistat.${SLURM_JOB_ID}
fi

done

echo "Finished SLURM job. $(date)"
