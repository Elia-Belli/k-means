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

echo "CREATING TEST RESULTS FILES"
for ((i=0; i < INPUT_NUM; i++));
do
  rm -r "${TEST_RESULTS}input_${i}.txt" 2>"/dev/null"
  touch "${TEST_RESULTS}input_${i}.txt"
  echo "${INPUT[i]} ${K[i]} ${ITER} ${MIN_CHANGES} ${MAX_DIST}" >> "${TEST_RESULTS}input_${i}.txt"
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