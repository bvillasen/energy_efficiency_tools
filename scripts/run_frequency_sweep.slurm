#!/bin/bash
#SBATCH -A ven114
#SBATCH -J freq_sweep
#SBATCH --time=0:10:00
#SBATCH --nodes=1
#SBATCH -e job_error.log
#SBATCH -o job_output.log
#SBATCH -q debug

#### Global parameters
EE_TOOLS_PATH=${HOME}/util/energy_efficiency_tools

#### Job parameters
WORK_DIR=$PWD
N_MPI=8
EXEC="${HOME}/code/cholla/bin/cholla.hydro.frontier parameter_file.txt"
AFFINITY="-c 7 --gpu-bind=closest"  



#### Setup application environment
SYSTEM=frontier source ${HOME}/code/cholla/scripts/set_env.sh


#### Setup omnistat
export OMNISTAT_VICTORIA_DATADIR=/tmp/omnistat/${SLURM_JOB_ID}
ml use /autofs/nccs-svm1_sw/crusher/amdsw/modules
ml omnistat-wrapper


#### Setup directory for energy counters
export ENERGY_COUNTER_DIR=${WORK_DIR}/energy_counters
if [ ! -d "${ENERGY_COUNTER_DIR}"]; then
  mkdir -p ${ENERGY_COUNTER_DIR}
fi


#### Run the frequency sweep job
echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"

# Start Omnistat (one second sampling rate)
${OMNISTAT_WRAPPER} usermode --start --interval 1

# Run the application
srun -n $N_MPI $AFFINITY ${EE_TOOLS_PATH}/tools/app_launcher.sh  $EXEC > ${WORK_DIR}/app_output.log

# Finish Omnistat, generate summary pdf and copy database
${OMNISTAT_WRAPPER} usermode --stopexporters
${OMNISTAT_WRAPPER} query --interval 1 --job ${SLURM_JOB_ID} --pdf omnistat.${SLURM_JOB_ID}.pdf
${OMNISTAT_WRAPPER} usermode --stopserver
mv /tmp/omnistat/${SLURM_JOB_ID} data_omnistat.${SLURM_JOB_ID}


echo "Finished SLURM job. $(date)"
