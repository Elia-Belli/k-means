#!/usr/bin/env bash
source config.sh

rm -r "${TEST_RESULTS}seq_strong.csv" "${TEST_RESULTS}mpi_strong.csv" "${TEST_RESULTS}omp_strong.csv"
rm -r "${TEST_RESULTS}seq_weak.csv" "${TEST_RESULTS}mpi_weak.csv" "${TEST_RESULTS}omp_weak.csv"
printf "time(s)\n" >> "${TEST_RESULTS}seq_strong.csv"
printf "input2,input4,input8,input16,input32\n" >> "${TEST_RESULTS}seq_weak.csv"

printf "p1,p2,p4,p8,p12,p16,p20,p24,p28,p32\n" >> "${TEST_RESULTS}mpi_strong.csv"
printf "p1,p2,p4,p8,p12,p16,p20,p24,p28,p32\n" >> "${TEST_RESULTS}omp_strong.csv"
printf "input2,input4,input8,input16,input32\n" >> "${TEST_RESULTS}mpi_weak.csv"
printf "input2,input4,input8,input16,input32\n" >> "${TEST_RESULTS}omp_weak.csv"
ulimit -s unlimited
export OMP_STACKSIZE=512M

echo "--------------------------"
echo "STRONG SCALING RUNS STARTING"

for ((i=0; i < TEST_RUN; i++));
  do
    ITERATIONS=${#STRONG_SCALING_THREADS[@]}

    if [ "${RUN_SEQUENTIAL_TESTS}" == true ]; then
      VERSION="seq"
      echo "[${i}] Running ${VERSION} version"

      OUTPUT=$(\
        ./bin/KMEANS_seq "${INPUT[STRONG_SCALING_INPUT]}" "${K[STRONG_SCALING_INPUT]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_${VERSION}_${STRONG_SCALING_INPUT}.txt"\
      )
      printf "%s\n" "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_strong.csv"

      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ "$RUN_MPI_TESTS" == true ]; then
      VERSION="mpi"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < ITERATIONS; j++));
      do
        echo "[${VERSION}] Running test with ${STRONG_SCALING_THREADS[j]} processes"

        OUTPUT=$(\
          mpirun --np "${STRONG_SCALING_THREADS[j]}" --oversubscribe\
          ./bin/KMEANS_mpi "${INPUT[STRONG_SCALING_INPUT]}" "${K[STRONG_SCALING_INPUT]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_${VERSION}_${STRONG_SCALING_INPUT}.txt"\
        )

        if [ $j != $((ITERATIONS - 1)) ]; then
          printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_strong.csv"
        fi
      done

      printf "%s\n" "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_strong.csv"

      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ "$RUN_OMP_TESTS" == true ]; then
      VERSION="omp"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < ITERATIONS; j++));
      do
        echo "[${VERSION}] Running test with ${STRONG_SCALING_THREADS[j]} processes"
        export OMP_NUM_THREADS=${STRONG_SCALING_THREADS[j]}

        OUTPUT=$(\
          ./bin/KMEANS_omp "${INPUT[STRONG_SCALING_INPUT]}" "${K[STRONG_SCALING_INPUT]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_${VERSION}_${STRONG_SCALING_INPUT}.txt"\
        )

        if [ $j != $((ITERATIONS - 1)) ]; then
          printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_strong.csv"
        fi
      done

      printf "%s\n" "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_strong.csv"

      echo "[${i}] ${VERSION} runs completed"
    fi
done

echo "--------------------------"
echo "WEAK SCALING RUNS STARTING"

# Runs for weak scaling
for ((i=0; i < TEST_RUN; i++));
  do
    ITERATIONS=${#INPUT[@]}

    if [ "${RUN_SEQUENTIAL_TESTS}" == true ]; then
      VERSION="seq"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < ITERATIONS; j++));
      do
        echo "[${VERSION}] Running test with ${INPUT[j]} processes"

        OUTPUT=$(\
          ./bin/KMEANS_seq "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt"\
        )

        if [ $j != $((ITERATIONS - 1)) ]; then
          printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_weak.csv"
        fi
      done

      printf "%s\n" "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_weak.csv"

      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ "$RUN_MPI_TESTS" == true ]; then
      VERSION="mpi"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < ITERATIONS; j++));
      do
        echo "[${VERSION}] Running test with ${STRONG_SCALING_THREADS[j]} and ${INPUT[j]}} processes"

        OUTPUT=$(\
          mpirun --np "${WEAK_SCALING_THREADS[j]}" --oversubscribe\
          ./bin/KMEANS_mpi "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt"\
        )

        if [ $j != $((ITERATIONS - 1)) ]; then
          printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_weak.csv"
        fi
      done

      printf "%s\n" "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_weak.csv"

      echo "[${i}] ${VERSION} runs completed"
    fi

    if [ "$RUN_OMP_TESTS" == true ]; then
      VERSION="omp"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < ITERATIONS; j++));
      do
        echo "[${VERSION}] Running test with ${STRONG_SCALING_THREADS[j]} and ${INPUT[j]}} processes"
        export OMP_NUM_THREADS=${WEAK_SCALING_THREADS[j]}

        OUTPUT=$(\
          ./bin/KMEANS_omp "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt"\
        )

        if [ $j != $((ITERATIONS - 1)) ]; then
          printf "%s," "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_weak.csv"
        fi
      done

      printf "%s\n" "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}_weak.csv"

      echo "[${i}] ${VERSION} runs completed"
    fi
done

echo "--------------------------"