#!/usr/bin/env bash
source config.sh
RUN_SEQ=true
RUN_LOCAL=false
RUN_SINGLE=false
RUN_COMBINED=false

for arg in $@;
do
  if [ "$arg" == "--skip" ]; then
    RUN_SEQ=false
  elif [ "$arg" == "--local" ]; then
    RUN_LOCAL=true
  elif [ "$arg" == "--single" ]; then
    RUN_SINGLE=true
  elif [ "$arg" == "--combined" ]; then
    RUN_COMBINED=true
  elif [ "$arg" == "--all" ]; then
    RUN_COMBINED=true
    RUN_SINGLE=true
  fi
done

if [ RUN_SINGLE == false ] && [ RUN_COMBINED == false ]; then
  echo "Please provide a test to run: --single, --combined or --all"
  exit 0;
fi

if [ "$RUN_SEQ" == true ]; then
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

if [ "$RUN_SEQ" == true ]; then
  echo "RUNNING SEQUENTIAL PROGRAM IN ORDER TO GATHER TESTS OUTCOMES"
  for ((i=0; i < INPUT_NUM; i++));
  do
    echo "[SEQUENTIAL] Running test ${i}"
    ./bin/KMEANS_seq "${INPUT[i]}" "${K[i]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_seq_${i}.txt" >> "${TEST_RESULTS}input_${i}.txt"
    printf "\n" >> "${TEST_RESULTS}input_${i}.txt"
  done
  echo "SEQUENTIAL PROGRAM RUNS COMPLETED. START TESTING:"
fi

echo
if [ "$RUN_LOCAL" == true ]; then
  if [ "$RUN_SINGLE" == true ]; then
    ./single_lib_tests.sh
  fi
else
  if [ "$RUN_SINGLE" == true ]; then
    condor_submit job.vanilla
  fi

  if [ "$RUN_COMBINED" == true ]; then
    condor_submit job.parallel
  fi
fi
