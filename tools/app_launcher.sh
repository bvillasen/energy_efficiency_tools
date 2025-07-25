#!/bin/bash

# Global rank and size
GLOBAL_RANK=$SLURM_PROCID
N_RANKS_GLOBAL=$SLURM_NTASKS

# Local rank and size
LOCAL_RANK=$SLURM_LOCALID
N_RANKS_LOCAL=$SLURM_NTASKS_PER_NODE
# N_RANKS_LOCAL=$SLURM_TASKS_PER_NODE

if [ ! -n "${N_RANKS_LOCAL}" ]; then
  N_RANKS_LOCAL=$(expr ${N_RANKS_GLOBAL} / ${SLURM_NNODES})
fi

NODE_ID=$(expr ${GLOBAL_RANK} / ${N_RANKS_LOCAL})
# echo "GLOBAL_RANK: ${GLOBAL_RANK}  N_RANKS_LOCAL: ${N_RANKS_LOCAL}  NODE_ID: ${NODE_ID}"

if [ ${LOCAL_RANK} -eq 0 ]; then
  RANK_IS_ROOT="1"
else
  RANK_IS_ROOT="0"
fi

# Get the hostname
HOSTNAME=$(hostname)

# List of devices to set the frequency cap
DEVICE_IDS=(0 1 2 3 4 5 6 7)

if [ -n "$FREQUENCY_CAP" ] && [ "$RANK_IS_ROOT" == "1" ]; then
  # Set the frequency cap on all devices on the node
  for DEVICE_ID in "${DEVICE_IDS[@]}"
  do
    set_freq_cmnd="/usr/bin/set_gpu_max_sclk -g ${DEVICE_ID} ${FREQUENCY_CAP}"
    echo -e "NodeID: ${NODE_ID}  ${set_freq_cmnd} "
    eval ${set_freq_cmnd} 
  done

  # Print the GPU frequency range
  # rocm-smi --showsclkrange
fi

if [ "$RANK_IS_ROOT" == "1" ]; then
  ENERGY_COUNTER_FILE=${ENERGY_COUNTER_DIR}/energy_start_node_${NODE_ID}${ENERGY_COUNTER_SUFFIX}.txt
  echo "NodeID: ${NODE_ID}  Collecting energy counter start. $(date)"
  cat /sys/cray/pm_counters/energy > ${ENERGY_COUNTER_FILE}
fi

APP_EXECUTABLE="$*"
eval "$APP_EXECUTABLE"

if [ "$RANK_IS_ROOT" == "1" ]; then
  ENERGY_COUNTER_FILE=${ENERGY_COUNTER_DIR}/energy_end_node_${NODE_ID}${ENERGY_COUNTER_SUFFIX}.txt
  echo "NodeID: ${NODE_ID}  Collecting energy counter end. $(date)"
  cat /sys/cray/pm_counters/energy > ${ENERGY_COUNTER_FILE}
fi