#!/usr/bin/env bash
source config.sh

export OMP_NUM_THREADS=$OMP_NUM_THREADS

for ((i=0; i < TEST_RUN; i++));
  do

    if [ $RUN_SEQUENTIAL_TESTS == true ]; then
      VERSION="seq"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        OUTPUT=$(./bin/KMEANS_seq ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt)
        COMPARISON=$(./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt")
        printf "%s,%s,%s\n" "${VERSION}" "${OUTPUT}" "${COMPARISON}" >> "${TEST_RESULTS}input_${j}.csv"
      done
      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ $RUN_MPI_TESTS == true ]; then
      VERSION="mpi"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        OUTPUT=$(\
          mpirun --bind-to none --np "${MPI_PROCESSES}" --oversubscribe \
          ./bin/KMEANS_mpi ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt \
        )
        COMPARISON=$(./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt")

        printf "%s,%s,%s\n" "${VERSION}" "${OUTPUT}" "${COMPARISON}" >> "${TEST_RESULTS}input_${j}.csv"
      done
      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ $RUN_OMP_TESTS == true ]; then
      VERSION="omp"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        OUTPUT=$(./bin/KMEANS_omp ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt)
        COMPARISON=$(./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt")

        printf "%s,%s,%s\n" "${VERSION}" "${OUTPUT}" "${COMPARISON}" >> "${TEST_RESULTS}input_${j}.csv"
      done
      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ $RUN_CUDA_TESTS == true ]; then
      VERSION="cuda"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        OUTPUT=$(./bin/KMEANS_cuda ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt)
        COMPARISON=$(./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt")

        printf "%s,%s,%s\n" "${VERSION}" "${OUTPUT}" "${COMPARISON}" >> "${TEST_RESULTS}input_${j}.csv"
      done
      echo "[${i}] ${VERSION} runs completed"
    fi
done
