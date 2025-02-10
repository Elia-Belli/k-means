#!/usr/bin/env bash
source config.sh

# Grant file permission to needed script
export RUN_WITH_OPENMP=true
chmod +xwr openmpiscript.sh
ulimit -s unlimited
export OMP_STACKSIZE=512M
NUM_MACHINES=$1


for ((i=0; i < TEST_RUN; i++));
  do
    ITERATIONS=${#INPUT_WEAK[@]}

    if [ "$RUN_MPI_OMP_TESTS" == true ]; then
        VERSION="mpi+omp"
        echo "[${i}] Running ${VERSION} version"

        for ((j=0; j < ITERATIONS; j++));
            do
                echo "[${VERSION}] Running test on ${INPUT_WEAK[j]}"

                OUTPUT=$(\
                ./bin/KMEANS_mpi+omp "${INPUT_WEAK[j]}" 100 "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_${VERSION}_${j}.txt"\
                )

                if [ $_CONDOR_PROCNO == 0 ]; then
                    printf "%s" "${OUTPUT}" >> "${TEST_RESULTS}input_weak_${VERSION}_${NUM_MACHINES}.csv"
                    cp "${TEST_RESULTS}input_weak_${VERSION}_${NUM_MACHINES}.csv" "${HOME}/k-means/tests"

                    if [ $j == $((ITERATIONS -1)) ]; then
                        printf "\n" "${OUTPUT}" >> "${TEST_RESULTS}input_weak_${VERSION}_${NUM_MACHINES}.csv"
                    fi
                fi
            done

        printf "%s\n" "${OUTPUT}" >> "${TEST_RESULTS}${VERSION}.csv"

        echo "[${i}] ${VERSION} runs completed"
    fi
done
echo "TESTS DONE, CHECK THE RESULTS IN ${TEST_RESULTS}"