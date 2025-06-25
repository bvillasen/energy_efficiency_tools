#!/bin/bash
#SBATCH -A ven114
#SBATCH -J freq_sweep
#SBATCH --time=0:10:00
#SBATCH --nodes=1
#SBATCH -e job_error.log
#SBATCH -o job_output.log
#SBATCH -q debug


#### Job parameters
WORK_DIR=$PWD
N_MPI=8
EXEC="${HOME}/code/cholla/bin/cholla.hydro.frontier parameter_file.txt"
AFFINITY="-c 7 --gpu-bind=closest"  


#### Setup environment
SYSTEM=frontier source ${HOME}/code/cholla/scripts/set_env.sh


echo "SLUM_NODES=$SLURM_NNODES  NODE_LIST:$SLURM_NODELIST"
echo "Starting SLURM job. $(date)"


echo "Starting application. $(date)"
srun -n $N_MPI $AFFINITY $EXEC > ${WORK_DIR}/app_output.log
echo "Finished application. $(date)"



echo "Finished SLURM job. $(date)"
