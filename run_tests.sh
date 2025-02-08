#!/usr/bin/env bash
source config.sh
RUN_SEQ=true
RUN_LOCAL=false
RUN_SINGLE=false
RUN_COMBINED=false
RUN_SCALING_TESTS=false

for arg in $@; do
  if [ "$arg" == "--skip" ]; then
    RUN_SEQ=false
  elif [ "$arg" == "--local" ]; then
    RUN_LOCAL=true
  elif [ "$arg" == "--scaling" ]; then
    RUN_SCALING_TESTS=true
  fi
done

if [ "$RUN_SEQ" == true ]; then
  make clean
fi
make all
make compare

rm -r ${TEST_RESULTS}input_*

echo "CREATING TEST RESULTS FILES"
for ((i = 0; i < INPUT_NUM; i++)); do
  touch "${TEST_RESULTS}input_${i}.csv"
  printf "${INPUT[i]},${K[i]},${ITER},${MIN_CHANGES},${MAX_DIST}\n" >>"${TEST_RESULTS}input_${i}.txt"

  if [ "$RUN_LOCAL" != true ]; then
    touch "${TEST_RESULTS}input_${i}_parallel.csv"
    printf "${INPUT[i]},${K[i]},${ITER},${MIN_CHANGES},${MAX_DIST}\n" >>"${TEST_RESULTS}input_${i}_parallel.txt"
  fi
done
echo "ALL RESULTS FILES ARE CREATED"

if [ "$RUN_SEQ" == true ]; then
  echo "RUNNING SEQUENTIAL PROGRAM IN ORDER TO GATHER TESTS OUTCOMES"
  for ((i = 0; i < INPUT_NUM; i++)); do
    echo "[SEQUENTIAL] Running test ${i}"
    {\
      printf "seq,"; \
      ./bin/KMEANS_seq "${INPUT[i]}" "${K[i]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_seq_${i}.txt"; \
      printf "\n"; \
    } >>"${TEST_RESULTS}input_${i}.csv"
  done
  echo "SEQUENTIAL PROGRAM RUNS COMPLETED. START TESTING:"
fi

echo
if [ "$RUN_LOCAL" == true ]; then
  ./single_lib_tests.sh
  ./combined_lib_tests_local.sh
else
  if [ "$RUN_SCALING_TESTS" == true ]; then
    condor_submit job.vanilla -append 'executable = scaling_tests.sh'
  elif [ $RUN_SEQUENTIAL_TESTS == true ] || [ $RUN_MPI_TESTS == true ] || [ $RUN_OMP_TESTS == true ] || [ $RUN_CUDA_TESTS == true ]; then
    condor_submit job.vanilla -append 'executable = single_lib_tests.sh'
  fi

  if [ $RUN_MPI_PARALLEL_TESTS == true ] || [ $RUN_MPI_OMP_TESTS == true ]; then
    condor_submit job.parallel -append 'executable = combined_lib_tests.sh'
  fi
fi

echo "TESTS DONE, CHECK THE RESULTS IN ${TEST_RESULTS}"
