#!/usr/bin/env bash
source config.sh

for ((i=0; i < ${#STRONG_SCALING_THREADS[@]}; i++));
do
  condor_submit job.parallel \
  -append 'executable = strong_scaling_combined.sh' \
  -append "machine_count = ${STRONG_SCALING_THREADS[i]}" \
  -append 'request_cpus = 32'
  -append "arguments = ${STRONG_SCALING_THREADS[i]}"
done