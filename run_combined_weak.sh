#!/usr/bin/env bash
source config.sh

for ((i=0; i < 10; i++));
do
  condor_submit job.parallel \
  -append "executable = weak_scaling_combined.sh" \
  -append "arguments = ${WEAK_SCALING_THREADS[i]}" \
  -append "machine_count = ${WEAK_SCALING_THREADS[i]}" \
  -append 'request_cpus = 32'
done