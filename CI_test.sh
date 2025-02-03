#!/usr/bin/bash
TESTDIR="./test_files/"
OUTDIR="./bin/out/"

TESTNUM=1
INPUT=("${TESTDIR}input2D.inp" "${TESTDIR}input2D2.inp" "${TESTDIR}input10D.inp" "${TESTDIR}input20D.inp" "${TESTDIR}input100D.inp" "${TESTDIR}input100D2.inp")
K=(100, 8, 100, 100, 100, 100)
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01

cd k-means

make clean
make compare
make KMEANS_seq
make KMEANS_mpi
make KMEANS_omp
make KMEANS_cuda
make KMEANS_mpi+omp

echo "START SEQUENTIAL PROGRAM"
for ((j=0; j < 6; j++));
do
  echo "--------------SEQ TEST: ${j}---------------"
  ./bin/KMEANS_seq "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_seq_${j}.txt"
done
echo "END SEQUENTIAL SECTION"

for ((i=0; i < TESTNUM; i++));
  do
    MPIPROCESSES=32
    export OMP_NUM_THREADS=32
    touch "./bin/out/result_run_${i}.txt"

    echo "START MPI VERSION TEST"

    for ((j=0; j < 6; j++));
    do
      echo "--------------MPI TEST: ${j}---------------" >> "./bin/out/result_run_${i}.txt"
      mpirun -np "${MPIPROCESSES}" --oversubscribe ./bin/KMEANS_mpi "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_mpi_${j}.txt" >> "./bin/out/result_run_${i}.txt"
      ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_mpi_${j}.txt" >> "./bin/out/result_run_${i}.txt"
    done

    echo "END MPI VERSION TEST"

    echo "START OMP VERSION TEST"

    for ((j=0; j < 6; j++));
    do
      echo "--------------OMP TEST: ${j}---------------" >> "./bin/out/result_run_${i}.txt"
      ./bin/KMEANS_omp "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_omp_${j}.txt" >> "./bin/out/result_run_${i}.txt"
      ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_omp_${j}.txt" >> "./bin/out/result_run_${i}.txt"
    done

    echo "END OMP VERSION TEST"

    echo "START CUDA VERSION TEST"

    for ((j=0; j < 6; j++));
    do
      echo "--------------CUDA TEST: ${j}---------------" >> "./bin/out/result_run_${i}.txt"
      ./bin/KMEANS_cuda "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_cuda_${j}.txt" >> "./bin/out/result_run_${i}.txt"
      ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_cuda_${j}.txt" >> "./bin/out/result_run_${i}.txt"
    done

  echo "END CUDA VERSION TEST"

  echo "START MPI+OMP VERSION TEST"

  MPIPROCESSES=4
  export OMP_NUM_THREADS=8
  for ((j=0; j < 6; j++));
  do
    echo "--------------MPI+OMP TEST: ${j}---------------" >> "./bin/out/result_run_${i}.txt"
    mpirun -np "${MPIPROCESSES}" --oversubscribe ./bin/KMEANS_mpi "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_mpi+omp_${j}.txt" >> "./bin/out/result_run_${i}.txt"
    ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_mpi+omp_${j}.txt" >> "./bin/out/result_run_${i}.txt"
  done
  echo "END MPI+OMP VERSION TEST"
done
echo "TEST ENDED"