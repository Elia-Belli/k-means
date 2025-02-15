#!/usr/bin/env bash
# ---------------------------------------------------------
# Change only this section of the file to modify test runs
TEST_DIR="./test_files/"
OUT_DIR="./bin/out/"
TEST_RESULTS="./tests/"

THREADS_TO_RUN=(1 2 4 8 12 16 20 24 28 32)

TEST_RUN=30
INPUT_NUM=9
INPUT=("${TEST_DIR}input3125x100.inp" "${TEST_DIR}input6250x100.inp" "${TEST_DIR}input12500x100.inp" "${TEST_DIR}input25000x100.inp" "${TEST_DIR}input37500x100.inp" "${TEST_DIR}input50000x100.inp" "${TEST_DIR}input62500x100.inp" "${TEST_DIR}input75000x100.inp" "${TEST_DIR}input87500x100.inp")
K=100
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01
# ---------------------------------------------------------

for ((i = 0; i < TEST_RUN; i++));
do
  VERSION="mpi"
  for ((j = 0; j < INPUT_NUM; j++));
  do
    for ((k = 0; k < INPUT_NUM; k++));
    do
      OUTPUT=$(\
        mpirun --bind-to none --np "${THREADS_TO_RUN[k]}" --oversubscribe \
        ./bin/KMEANS_mpi ${INPUT[j]} ${K} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt \
      )
      printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_${INPUT[j]}_strong.csv"
    done
    printf "\n" >> "${TEST_RESULTS}${VERSION}_${INPUT[j]}_strong.csv"
  done

  VERSION="omp"
  for ((j = 0; j < INPUT_NUM; j++));
  do
    for ((k = 0; k < INPUT_NUM; k++));
    do
      export OMP_NUM_THREADS=${THREADS_TO_RUN[k]}
      OUTPUT=$(\
        ./bin/KMEANS_omp ${INPUT[j]} ${K} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt \
      )
      printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_${INPUT[j]}_strong.csv"
    done
    printf "\n" >> "${TEST_RESULTS}${VERSION}_${INPUT[j]}_strong.csv"
  done
done