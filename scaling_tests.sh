#!/usr/bin/env bash


for ((i = 0; i < TEST_RUN; i++));
do
  VERSION="mpi"
  for ((j = 0; j < INPUT_NUM; j++));
  do
    for ((k = 0; k < INPUT_NUM; k++));
    do
      OUTPUT=$(\
        mpirun --bind-to none --np "${THREADS_TO_RUN[k]}" --oversubscribe \
        ./bin/KMEANS_mpi "${INPUT[j]}" ${K} ${ITER} ${MIN_CHANGES} ${MAX_DIST} "${OUT_DIR}KMEANS_${VERSION}_${j}.txt" \
      )
      printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_${j}_strong.csv"
    done
    printf "\n" >> "${TEST_RESULTS}${VERSION}_${j}_strong.csv"
  done

  VERSION="omp"
  for ((j = 0; j < INPUT_NUM; j++));
  do
    for ((k = 0; k < INPUT_NUM; k++));
    do
      export OMP_NUM_THREADS=${THREADS_TO_RUN[k]}
      OUTPUT=$(\
        ./bin/KMEANS_omp "${INPUT[j]}" ${K} ${ITER} ${MIN_CHANGES} ${MAX_DIST} "${OUT_DIR}KMEANS_${VERSION}_${j}.txt" \
      )
      printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_${j}_strong.csv"
    done
    printf "\n" >> "${TEST_RESULTS}${VERSION}_${j}_strong.csv"
  done
done