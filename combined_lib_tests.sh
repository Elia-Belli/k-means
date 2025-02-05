#!/usr/bin/env bash
source config.sh
# TODO: add if
for ((i=0; i < TEST_RUN; i++));
  do
    if [ $RUN_MPI_OMP_TESTS == true ]; then
      echo "[${i}] Running MPI+OMP version"
      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[MPI+OMP] Running test ${j}"
        {\
          ./openmpiscript_mod.sh ./bin/KMEANS_mpi+omp ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_mpi+omp_${j}.txt; \
          printf ","; \
          ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_mpi+omp_${j}.txt"
        } >> "${TEST_RESULTS}input_${j}_parallel.txt"
        cp "${TEST_RESULTS}input_${j}_parallel.txt" "${HOME}/k-means/tests"
      done
      echo "[${i}] MPI+OMP runs completed"
    fi

    if [ $RUN_MPI_PARALLEL_TESTS == true ]; then
      echo "[${i}] Running MPI parallel version"
      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[MPI PARALLEL] Running test ${j}"
        {\
          ./openmpiscript_mod.sh ./bin/KMEANS_mpi ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_mpi_${j}.txt; \
          printf ","; \
          ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_mpi_${j}.txt"
        } >> "${TEST_RESULTS}input_${j}_parallel.txt"
        cp "${TEST_RESULTS}input_${j}_parallel.txt" "${HOME}/k-means/tests"
      done
      echo "[${i}] MPI parallel runs completed"
    fi
done
echo "TESTS DONE, CHECK THE RESULTS IN ${TEST_RESULTS}"
