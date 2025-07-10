#!/bin/bash
#SBATCH -A ven114
#SBATCH -J freq_sweep
#SBATCH --time=0:15:00
#SBATCH --nodes=1
#SBATCH -e job_error.log
#SBATCH -o job_output.log
#SBATCH -q debug

#### Global parameters
EE_TOOLS_PATH=${HOME}/util/energy_efficiency_tools
FREQUENCY_CAP_VALS=(1700 1400 1100 800)
# FREQUENCY_CAP_VALS=(1700 1600 1500 1400 1300 1200 1100 1000 900 800 700)


#### Job parameters
WORK_DIR=$PWD
N_MPI=8
EXEC="${HOME}/code/cholla/bin/cholla.hydro.frontier parameter_file.txt"
AFFINITY="-c 7 --gpu-bind=closest"  


#### Setup application environment
SYSTEM=frontier source ${HOME}/code/cholla/scripts/set_env.sh


#### Setup Omnistat
export OMNISTAT_VICTORIA_DATADIR=/tmp/omnistat/${SLURM_JOB_ID}
SAMPLING_INTERVAL=0.1
ml use /autofs/nccs-svm1_sw/crusher/amdsw/modules
ml omnistat-wrapper/1.6.0


#### Run the frequency sweep job
echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"

# Loop over the frequency caps 
for MAX_SCLK in "${FREQUENCY_CAP_VALS[@]}"
do

  export FREQUENCY_CAP=$MAX_SCLK
  echo "###### Starting run with frequency cap: ${FREQUENCY_CAP} MHz"
  
  # Setup directory for this FREQUENCY_CAP
  RUN_DIR=${WORK_DIR}/maxsclk_${FREQUENCY_CAP}
  if [ ! -d "${RUN_DIR}" ]; then
    mkdir -p ${RUN_DIR}
  fi

  # Setup directory for energy counters
  export ENERGY_COUNTER_DIR=${RUN_DIR}

  # Start Omnistat
  ${OMNISTAT_WRAPPER} usermode --start --interval ${SAMPLING_INTERVAL}

  # Run the application
  echo "Starting application. $(date)"
  echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_start.txt
  srun -n $N_MPI $AFFINITY ${EE_TOOLS_PATH}/tools/app_launcher.sh  $EXEC > ${RUN_DIR}/app_output.txt
  echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_end.txt
  echo "Finished application. $(date)"

  # Finish Omnistat, generate summary pdf and copy database
  ${OMNISTAT_WRAPPER} usermode --stopexporters
  ${OMNISTAT_WRAPPER} query --interval ${SAMPLING_INTERVAL} --job ${SLURM_JOB_ID} --pdf ${RUN_DIR}/omnistat.${SLURM_JOB_ID}.pdf --export ${RUN_DIR}
  ${OMNISTAT_WRAPPER} usermode --stopserver
  mv /tmp/omnistat/${SLURM_JOB_ID} ${RUN_DIR}/data_omnistat.${SLURM_JOB_ID}

  echo "###### Finished run with frequency cap: ${FREQUENCY_CAP} MHz"
  
done

echo "Finished SLURM job. $(date)"
