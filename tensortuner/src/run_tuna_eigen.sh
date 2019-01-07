#!/bin/bash
set -e

if [ $# -ne 3 ];
then
  echo "run_tuna_eigen.sh <model> <batch_size> <cpu>"
  echo "<cpu> options: skl"
  echo "<model> options come from running this: python run_single_node_benchmark.py -h"
  exit 0
fi

model=$1
batch_size=$2
cpu=$3

#############################
# Configs

HOME_DIR=${HOME:-/home/user}
LOG_DIR=${LOG_DIR:-/tmp}
TF_CNN_DIR=${TF_CNN_DIR:-${HOME_DIR}/private-tensorflow-benchmarks/scripts/tf_cnn_benchmarks}

#############################
# Tuna configs

CFG_SEARCH=nm
#CFG_SEARCH=exhaustive
CFG_INFERENCE=False
CFG_INIT_RADIUS=0.9
CFG_OUTPUT=output

#############################

mkdir -p ${LOG_DIR}/logs/${cpu}/${CFG_OUTPUT}/${CFG_SEARCH}/eigen

if [ "$cpu" = "skl" ];
then
  intra_op_min=14
  intra_op_max=56
  intra_op_step=7
  inter_op_min=1
  inter_op_max=4
  inter_op_step=1
else
  intra_op_min=11
  intra_op_max=44
  intra_op_step=11
  inter_op_min=1
  inter_op_max=4
  inter_op_step=1
fi

if [ "$CFG_INFERENCE" = "True" ];
then
  LOG=${CURR_DIR}/logs/${cpu}/${CFG_OUTPUT}/${CFG_SEARCH}/eigen/${model}.inference.tuna.${CFG_SEARCH}.log
else
  LOG=${CURR_DIR}/logs/${cpu}/${CFG_OUTPUT}/${CFG_SEARCH}/eigen/${model}.train.tuna.${CFG_SEARCH}.log
fi

INIT_RADIUS=${CFG_INIT_RADIUS} \
STRATEGY=${CFG_SEARCH}.so LAYERS=log.so \
LOG_FILE=${LOG} \
${HARMONY_HOME}/bin/tuna \
-q -v -n=200 \
-i=interop,${inter_op_min},${inter_op_max},${inter_op_step} \
-i=intraop,${intra_op_min},${intra_op_max},${intra_op_step} \
-m=${CFG_OUTPUT} python ${TF_CNN_DIR}/tf_cnn_benchmarks.py \
--forward_only=${CFG_INFERENCE} \
--num_warmup_batches=0 \
--batch_size=${batch_size} \
--data_format=NHWC --model=${model} \
--num_batches=100 \
--num_inter_threads=%interop \
--num_intra_threads=%intraop
