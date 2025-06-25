#!/bin/bash

# Global rank and size
GLOBAL_RANK=$SLURM_PROCID
N_RANKS_GLOBAL=$SLURM_NTASKS

# Local rank and size
LOCAL_RANK=$SLURM_LOCALID
N_RANKS_LOCAL=$SLURM_TASKS_PER_NODE

NODE_ID=$(expr ${GLOBAL_RANK} / ${N_RANKS_LOCAL})
if [ ${LOCAL_RANK} -eq 0 ]; then
  RANK_IS_ROOT="1"
else
  RANK_IS_ROOT="0"
fi

# Get the hostname
HOSTNAME=$(hostname)

if [ "$RANK_IS_ROOT" == "1" ]; then
  ENERGY_COUNTER_FILE=${ENERGY_COUNTER_DIR}/energy_start_node_${NODE_ID}${ENERGY_COUNTER_SUFFIX}.txt
  echo "Collecting energy counter start. $(date)"
  cat /sys/cray/pm_counters/energy > ${ENERGY_COUNTER_FILE}
fi

APP_EXECUTABLE="$*"
eval "$APP_EXECUTABLE"

if [ "$RANK_IS_ROOT" == "1" ]; then
  ENERGY_COUNTER_FILE=${ENERGY_COUNTER_DIR}/energy_end_node_${NODE_ID}${ENERGY_COUNTER_SUFFIX}.txt
  echo "Collecting energy counter end. $(date)"
  cat /sys/cray/pm_counters/energy > ${ENERGY_COUNTER_FILE}
fi