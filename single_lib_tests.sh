#!/usr/bin/env bash
source config.sh

for ((i=0; i < TEST_RUN; i++));
  do
    echo "[${i}] Running MPI version"
    for ((j=0; j < INPUT_NUM; j++));
    do
      echo "[MPI] Running test ${j}"
      {\
        mpirun -np "${MPI_PROCESSES}" --oversubscribe ./bin/KMEANS_mpi "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_mpi_${j}.txt" 2>"/dev/null"; \
        printf ","; \
        ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_mpi_${j}.txt" >> "${TEST_RESULTS}input_${j}.txt"
      } >> "${TEST_RESULTS}input_${j}.txt"
    done

    echo "[${i}] Mpi runs completed"

    echo "[${i}] Running OpenMP version"

    for ((j=0; j < INPUT_NUM; j++));
    do
      echo "[OPENMP] Running test ${j}"
      {\
        ./bin/KMEANS_omp "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_omp_${j}.txt"; \
        printf ","; \
        ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_omp_${j}.txt" >> "${TEST_RESULTS}input_${j}.txt"
      } >> "${TEST_RESULTS}input_${j}.txt"
    done

    echo "[${i}] OpenMP runs completed"

    echo "[${i}] Running Cuda version"

#    for ((j=0; j < INPUT_NUM; j++));
#    do
#      echo "[CUDA] Running test ${j}"
#      {\
#        ./bin/KMEANS_cuda "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUT_DIR}KMEANS_cuda_${j}.txt"; \
#        printf ","; \
#        ./bin/compare "${OUT_DIR}KMEANS_seq_${j}.txt" "${OUT_DIR}KMEANS_cuda_${j}.txt" >> "${TEST_RESULTS}input_${j}.txt"
#      } >> "${TEST_RESULTS}input_${j}.txt"
#    done
#    echo "[${i}] Cuda runs completed"
done
