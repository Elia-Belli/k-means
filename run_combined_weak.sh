#!/usr/bin/env bash
source config.sh

for ((i=0; i < 5; i++));
do
  condor_submit job.parallel \
  -append "executable = weak_scaling_combined.sh" \
  -append "arguments = ${NODES_WEAK_MPI_OMP[i]}" \
  -append "machine_count = ${NODES_WEAK_MPI_OMP[i]}" \
  -append 'request_cpus = 32'
done