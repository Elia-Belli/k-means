#!/usr/bin/env bash
source config.sh

# Grant file permission to needed script
chmod +xwr openmpiscript.sh bin/compare

for ((i=0; i < TEST_RUN; i++));
  do
    if [ $RUN_MPI_OMP_TESTS == true ]; then
      VERSION="mpi+omp"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        {\
          printf "${VERSION},"; \
          ./openmpiscript.sh ./bin/KMEANS_mpi+omp ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt; \
          printf ","; \
          ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "$HOME/k-means/bin/out/KMEANS_${VERSION}_${j}.txt"; \
        } >> "${TEST_RESULTS}input_${j}_parallel.csv"
        cp "${TEST_RESULTS}input_${j}_parallel.csv" "${HOME}/k-means/tests"
      done
      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ $RUN_MPI_PARALLEL_TESTS == true ]; then
      VERSION="mpi_parallel"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        {\
          printf "${VERSION},"; \
          ./openmpiscript.sh ./bin/KMEANS_mpi ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt; \
          printf ","; \
          ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "$HOME/k-means/bin/out/KMEANS_${VERSION}_${j}.txt"; \
        } >> "${TEST_RESULTS}input_${j}_parallel.csv"
        cp "${TEST_RESULTS}input_${j}_parallel.csv" "${HOME}/k-means/tests"
      done
      echo "[${i}] ${VERSION} runs completed"
    fi
done
echo "TESTS DONE, CHECK THE RESULTS IN ${TEST_RESULTS}"
