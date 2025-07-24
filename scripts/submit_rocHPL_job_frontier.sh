#!/bin/bash
#SBATCH -J rocHPL
#SBATCH -A ven114 
#SBATCH --time=0:08:00     # EDIT: Time limit for the job
#SBATCH --nodes=1          # EDIT: Number of nodes for the job
#SBATCH -e job_error.log
#SBATCH -o job_output.log


#### Global parameters
EE_TOOLS_PATH=${HOME}/util/energy_efficiency_tools  # EDIT: location of the energy_efficiency_tools directory 
ROCHPL_EXEC=${HOME}/code/energy_efficiency/apps/rocHPL/code/rocHPL/build/run_rochpl
ROCHPLMXP_EXEC=${HOME}/code/energy_efficiency/apps/rocHPL-MxP/code/rocHPL-MxP/build/run_rochplmxp

#### Job parameters
WORK_DIR=$PWD                          # EDIT: Work directory for the frequency sweep 
N_MPI_PER_NODE=8                       # EDIT: Number of MPI ranks per node 
N_CORES=7
AFFINITY="-c ${N_CORES} --cpu-bind=cores --threads-per-core=1 --gpus-per-task=1 --gpu-bind=closest" 
N_NODES=${SLURM_JOB_NUM_NODES}
N_MPI=$((N_NODES*N_MPI_PER_NODE))

echo "N_NODES: ${N_NODES}"
echo "N_MPI_PER_NODE: ${N_MPI_PER_NODE}"
echo "N_MPI: ${N_MPI}"

#### Set app environment
module load PrgEnv-gnu
module load rocm
module load gcc
module load craype-accel-amd-gfx90a
export MPICH_GPU_SUPPORT_ENABLED=1
module list


#### Setup Omnistat
export OMNISTAT_VICTORIA_DATADIR=/tmp/omnistat/${SLURM_JOB_ID}
SAMPLING_INTERVAL=0.1
ml use /autofs/nccs-svm1_sw/crusher/amdsw/modules
ml omnistat-wrapper/1.6.0

##################################################
echo "SLUM_NODES=$SLURM_JOB_NUM_NODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"

# Multi rank configuration
if [ "${N_MPI}" -eq 1 ]; then
  HPL_P=1; HPL_Q=1; HPL_N=90112; HPL_p=1; HPL_q=1;
elif [ "${N_MPI}" -eq 2 ]; then
  HPL_P=1; HPL_Q=2; HPL_N=128000; HPL_p=1; HPL_q=2;
elif [ "${N_MPI}" -eq 4 ]; then
  HPL_P=2; HPL_Q=2; HPL_N=180224; HPL_p=2; HPL_q=2; 
elif [ "${N_MPI}" -eq 8 ]; then
  HPL_P=2; HPL_Q=4; HPL_N=256000; HPL_p=2; HPL_q=4; 
elif [ "${N_MPI}" -eq 16 ]; then
  HPL_P=4; HPL_Q=4; HPL_N=362000; HPL_p=2; HPL_q=4;
elif [ "${N_MPI}" -eq 32 ]; then
  HPL_P=4; HPL_Q=8; HPL_N=512000; HPL_p=2; HPL_q=4;
elif [ "${N_MPI}" -eq 64 ]; then
  HPL_P=8; HPL_Q=8; HPL_N=724000; HPL_p=2; HPL_q=4; 
elif [ "${N_MPI}" -eq 128 ]; then
  HPL_P=8; HPL_Q=16; HPL_N=1024000; HPL_p=2; HPL_q=4;
elif [ "${N_MPI}" -eq 256 ]; then
  HPL_P=16; HPL_Q=16; HPL_N=1448000; HPL_p=2; HPL_q=4; 
else
  echo -e "${RED}ERROR. Configuration is not set for N_MPI=${N_MPI} ${NC}"
  return
fi

HPL_NB=512
HPL_f=0.3
N_ITER=1
export OMP_NUM_THREADS=${N_CORES}

export RUN_DIR=${WORK_DIR}/rocHPL
if [ ! -d "${RUN_DIR}" ]; then
  mkdir -p ${RUN_DIR}
fi
export ENERGY_COUNTER_DIR=${RUN_DIR}

echo -e "Using rocHPL configuration for N_MPI=${N_MPI}"
echo -e "HPL MPI grid N rows [P]: ${HPL_P}"
echo -e "HPL MPI grid N columns [Q]: ${HPL_Q}"
echo -e "HPL matrix size [N]: ${HPL_N}"
echo -e "HPL panel size [NB]: ${HPL_NB}"
echo -e "HPL N iterations: ${N_ITER}"
echo -e "OMP_NUM_THREADS: ${OMP_NUM_THREADS}"
echo -e "RUN_DIR: ${RUN_DIR}"


# ROCHPL_CMD="${ROCHPL_EXEC} -P ${HPL_P} -Q ${HPL_Q} -p ${HPL_p} -q ${HPL_q} -N ${HPL_N} --NB ${HPL_NB} -f ${HPL_f} --it ${N_ITER}"
# echo "ROCHPL_CMD: ${ROCHPL_CMD}"

# # Start Omnistat
# ${OMNISTAT_WRAPPER} usermode --start --interval ${SAMPLING_INTERVAL}

# # Run the application
# echo "Starting rocHPL. $(date)"
# echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_start.txt

# srun -n ${N_MPI} ${AFFINITY} $EE_TOOLS_PATH/tools/app_launcher.sh $ROCHPL_CMD > ${RUN_DIR}/app_output.txt

# echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_end.txt
# echo "Finished rocHPL. $(date)"

# # Finish Omnistat, generate summary pdf and copy database
# ${OMNISTAT_WRAPPER} usermode --stopexporters
# ${OMNISTAT_WRAPPER} query --interval ${SAMPLING_INTERVAL} --job ${SLURM_JOB_ID} --pdf ${RUN_DIR}/omnistat.${SLURM_JOB_ID}.pdf --export ${RUN_DIR}
# ${OMNISTAT_WRAPPER} usermode --stopserver
# mv /tmp/omnistat/${SLURM_JOB_ID} ${RUN_DIR}/data_omnistat.${SLURM_JOB_ID}
# mv exporter.log vic_server.log ${RUN_DIR}


export RUN_DIR=${WORK_DIR}/rocHPL-MxP
if [ ! -d "${RUN_DIR}" ]; then
  mkdir -p ${RUN_DIR}
fi
export ENERGY_COUNTER_DIR=${RUN_DIR}


ROCHPLMXP_CMD="${ROCHPLMXP_EXEC} -P ${HPL_P} -Q ${HPL_Q} -p ${HPL_p} -q ${HPL_q} -N ${HPL_N} --NB ${HPL_NB} -f ${HPL_f} --it ${N_ITER}"
echo "ROCHPLMXP_CMD: ${ROCHPLMXP_CMD}"

# Start Omnistat
${OMNISTAT_WRAPPER} usermode --start --interval ${SAMPLING_INTERVAL}

# Run the application
echo "Starting rocHPL-MxP. $(date)"
echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_start.txt

srun -n ${N_MPI} ${AFFINITY} $EE_TOOLS_PATH/tools/app_launcher.sh $ROCHPLMXP_CMD > ${RUN_DIR}/app_output.txt

echo $(date +"%Y-%m-%d %H:%M:%S.%N") > ${RUN_DIR}/time_end.txt
echo "Finished rocHPL-MxP. $(date)"

# Finish Omnistat, generate summary pdf and copy database
${OMNISTAT_WRAPPER} usermode --stopexporters
${OMNISTAT_WRAPPER} query --interval ${SAMPLING_INTERVAL} --job ${SLURM_JOB_ID} --pdf ${RUN_DIR}/omnistat.${SLURM_JOB_ID}.pdf --export ${RUN_DIR}
${OMNISTAT_WRAPPER} usermode --stopserver
mv /tmp/omnistat/${SLURM_JOB_ID} ${RUN_DIR}/data_omnistat.${SLURM_JOB_ID}
mv exporter.log vic_server.log ${RUN_DIR}




echo "Finished SLURM job. $(date)"
