#!/usr/bin/env bash
source config.sh

# Grant file permission to needed script
export RUN_WITH_OPENMP=true
chmod +xwr openmpiscript.sh bin/compare
ulimit -s unlimited
export OMP_STACKSIZE=512M
INPUT_NUM=${#INPUT[@]}

for ((i=0; i < TEST_RUN; i++));
  do
    if [ $RUN_MPI_OMP_TESTS == true ]; then
      VERSION="mpi+omp"
      echo "[${i}] Running ${VERSION} version"

      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[${VERSION}] Running test ${j}"
        OUTPUT=$(./openmpiscript.sh ./bin/KMEANS_mpi+omp ${INPUT[j]} ${K[j]} ${ITER} ${MIN_CHANGES} ${MAX_DIST} ${OUT_DIR}KMEANS_${VERSION}_${j}.txt)
        COMPARISON=$(./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "$HOME/k-means/bin/out/KMEANS_${VERSION}_${j}.txt")

        if [ $_CONDOR_PROCNO == 0 ]; then
          printf "%s,%s,%s\n" "${VERSION}" "${OUTPUT}" "${COMPARISON}" >> "${TEST_RESULTS}input_${j}_${VERSION}.csv"
          cp "${TEST_RESULTS}input_${j}_${VERSION}.csv" "${HOME}/k-means/tests"
        fi
      done
      echo "[${i}] ${VERSION} runs completed"
    fi
done
echo "TESTS DONE, CHECK THE RESULTS IN ${TEST_RESULTS}"
