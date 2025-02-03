#!/usr/bin/bash
# ---------------------------------------------------------
# Change only this section of the file to modify test runs
TEST_DIR="./test_files/"
OUT_DIR="./bin/out/"
TEST_RESULTS="tests/"

MPI_PROCESSES=8
export OMP_NUM_THREADS=32

TEST_RUN=1
INPUT_NUM=6
INPUT=("${TEST_DIR}input2D.inp" "${TEST_DIR}input2D2.inp" "${TEST_DIR}input10D.inp" "${TEST_DIR}input20D.inp" "${TEST_DIR}input100D.inp" "${TEST_DIR}input100D2.inp")
K=(100, 8, 100, 100, 100, 100)
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01
# ---------------------------------------------------------

echo "CREATING TEST RESULTS FILES"
for ((i=0; i < INPUT_NUM; i++));
do
  rm -r "${TEST_RESULTS}input_${i}.txt" 2>"/dev/null"
  touch "${TEST_RESULTS}input_${i}.txt"
  echo "Running tests on input: ${INPUT[i]} ${K[i]} ${ITER} ${MIN_CHANGES} ${MAX_DIST}" >> "${TEST_RESULTS}input_${i}.txt"
done
echo "ALL RESULTS FILES ARE CREATED"


echo "RUNNING SEQUENTIAL PROGRAM IN ORDER TO GATHER TESTS OUTCOMES"
for ((i=0; i < INPUT_NUM; i++));
do
  echo "[SEQUENTIAL] Running test ${i}"
  ./bin/KMEANS_seq "${INPUT[i]}" "${K[i]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_seq_${i}.txt" >> "${TEST_RESULTS}input_${i}.txt"
done
echo "SEQUENTIAL PROGRAM RUNS COMPLETED. START TESTING:"

for ((i=0; i < TEST_RUN; i++));
  do
    echo "[${i}] Running MPI+OMP version"
    for ((j=0; j < INPUT_NUM; j++));
    do
      echo "[MPI+OMP] Running test ${j}"
      # shellcheck disable=SC2129
      echo "[MPI+OMP]"
      ./openmpiscript.sh "./bin/KMEANS_mpi ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_mpi+omp_${j}.txt" 2>"/dev/null"
      ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_mpi+omp_${j}.txt"
    done
done
echo "TESTS DONE, CHECK THE RESULTS IN ${TEST_RESULTS}"
