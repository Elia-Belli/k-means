TESTDIR="./test_files/"
OUTDIR="./bin/out/"
MPIPROCESSES=12
export OMP_NUM_THREADS=12

TESTNUM=1
INPUT=("${TESTDIR}input2D.inp" "${TESTDIR}input2D2.inp" "${TESTDIR}input10D.inp" "${TESTDIR}input20D.inp" "${TESTDIR}input100D.inp" "${TESTDIR}input100D2.inp")
K=(100, 8, 16, 64, 128, 256)
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01

make compare
make KMEANS_seq

echo "START SEQUENTIAL VERSION TEST"

for ((i=0; i < TESTNUM; i++));
do
  for ((j=0; j < 6; j++));
  do
    echo "--------------SEQ TEST: ${j}---------------"
    ./bin/KMEANS_seq "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_seq_${j}.txt"
  done
done

echo "END SEQUENTIAL VERSION TEST"

make KMEANS_mpi

echo "START MPI VERSION TEST"

for ((i=0; i < TESTNUM; i++));
do
  for ((j=0; j < 6; j++));
  do
    echo "--------------MPI TEST: ${j}---------------"
    mpirun -np "${MPIPROCESSES}" --oversubscribe ./bin/KMEANS_mpi "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_mpi_${j}.txt"
    ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_mpi_${j}.txt"
  done
done

echo "END MPI VERSION TEST"

make KMEANS_omp

echo "START OMP VERSION TEST"

for ((i=0; i < TESTNUM; i++));
do
  for ((j=0; j < 6; j++));
  do
    echo "--------------OMP TEST: ${j}---------------"
    ./bin/KMEANS_omp "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_omp_${j}.txt"
    ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_omp_${j}.txt"
  done
done

echo "END OMP VERSION TEST"

make KMEANS_cuda

echo "START CUDA VERSION TEST"

for ((i=0; i < TESTNUM; i++));
do
  for ((j=0; j < 6; j++));
  do
    echo "--------------CUDA TEST: ${j}---------------"
    ./bin/KMEANS_cuda "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_cuda_${j}.txt"
    ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_cuda_${j}.txt"
  done
done

echo "END CUDA VERSION TEST"

make KMEANS_mpi+omp

echo "START MPI + OMP VERSION TEST"

for ((i=0; i < TESTNUM; i++));
do
  for ((j=0; j < 6; j++));
  do
    echo "--------------MPI+OMP TEST: ${j}---------------"
    mpirun -np "${MPIPROCESSES}" --oversubscribe ./bin/KMEANS_mpi+omp "${INPUT[j]}" "${K[j]}" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "${OUTDIR}KMEANS_mpi+omp_${j}.txt"
    ./bin/compare "${OUTDIR}KMEANS_seq_${j}.txt" "${OUTDIR}KMEANS_mpi+omp_${j}.txt"
  done
done

echo "END MPI + OMP VERSION TEST"

