#!/usr/bin/env bash
source config.sh

export OMP_NUM_THREADS=$OMP_NUM_THREADS_COMBINED

for ((i=0; i < TEST_RUN; i++));
  do
    if [ $RUN_MPI_OMP_TESTS == true ]; then
      echo "[${i}] Running MPI+OMP version"
      for ((j=0; j < INPUT_NUM; j++));
      do
        echo "[MPI+OMP] Running test ${j}"
        {\
          mpirun --bind-to none --np "${MPI_PROCESSES_COMBINED}" --oversubscribe ./bin/KMEANS_mpi+omp "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_mpi+omp_${j}.txt" 2>"${OUT_DIR}KMEANS_mpi+omp_${j}_error.txt"; \
          printf ","; \
          ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_mpi+omp_${j}.txt"
        } >> "${TEST_RESULTS}input_${j}.txt"
      done
      echo "[${i}] MPI+OMP runs completed"
    fi
done
