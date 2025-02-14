#!/usr/bin/env bash
source config.sh

for ((i=0; i < 10; i++));
do
  condor_submit job.parallel \
  -append "executable = strong_scaling_combined.sh" \
  -append "arguments = ${NODES_STRONG_MPI_OMP[i]}" \
  -append "machine_count = ${NODES_STRONG_MPI_OMP[i]}" \
  -append 'request_cpus = 32'
done