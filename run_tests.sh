#!/usr/bin/env bash
source config.sh
RUN_SEQ=true

if [ $# -ne 0 ]
  then
    RUN_SEQ=$1
fi

if [ "$RUN_SEQ" != "--skip" ]
  then
    make clean
fi
make all
make compare

rm -r ${TEST_RESULTS}input_*

echo "CREATING TEST RESULTS FILES"
for ((i=0; i < INPUT_NUM; i++));
do
  touch "${TEST_RESULTS}input_${i}.txt"
  printf "${INPUT[i]},${K[i]},${ITER},${MIN_CHANGES},${MAX_DIST}\n" >> "${TEST_RESULTS}input_${i}.txt"
  touch "${TEST_RESULTS}input_${i}_parallel.txt"
  printf "${INPUT[i]},${K[i]},${ITER},${MIN_CHANGES},${MAX_DIST}\n" >> "${TEST_RESULTS}input_${i}_parallel.txt"
done
echo "ALL RESULTS FILES ARE CREATED"

if [ "$RUN_SEQ" != "--skip" ]
  then
    echo "RUNNING SEQUENTIAL PROGRAM IN ORDER TO GATHER TESTS OUTCOMES"
    for ((i=0; i < INPUT_NUM; i++));
    do
      echo "[SEQUENTIAL] Running test ${i}"
      ./bin/KMEANS_seq "${INPUT[i]}" "${K[i]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_seq_${i}.txt" >> "${TEST_RESULTS}input_${i}.txt"
      printf "\n" >> "${TEST_RESULTS}input_${i}.txt"
    done
    echo "SEQUENTIAL PROGRAM RUNS COMPLETED. START TESTING:"
fi

condor_submit job.vanilla

condor_submit job.parallel