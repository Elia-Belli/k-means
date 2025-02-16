#!/usr/bin/env bash
source config.sh

export OMP_NUM_THREADS=$OMP_NUM_THREADS_COMBINED
INPUT_NUM=${#INPUT[@]}

for ((i=0; i < TEST_RUN; i++));
  do
    if [ $RUN_MPI_OMP_TESTS == true ]; then
      VERSION="mpi+omp"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        OUTPUT=$(\
          mpirun --bind-to none --np "${MPI_PROCESSES_COMBINED}" --oversubscribe \
          ./bin/KMEANS_mpi+omp ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt \
        )
        COMPARISON=$(./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt")

        printf "%s,%s,%s\n" "${VERSION}" "${OUTPUT}" "${COMPARISON}" >> "${TEST_RESULTS}input_${j}.csv"
      done
      echo "[${i}] ${VERSION} runs completed"
    fi
done
