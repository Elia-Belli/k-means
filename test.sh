TESTNUM=1
INPUT="./k-means/test_files/input100D2.inp"
K=10000
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01

MPI_EXE=./k-means/bin/KMEANS_mpi
OMP_EXE=./k-means/bin/KMEANS_omp
CUDA_EXE=./k-means/bin/KMEANS_cuda

cd k-means
make KMEANS_mpi
make KMEANS_omp
cd ..

rm "logs/test_mpi.txt"
rm "logs/test_omp.txt"

for ((i=0; i < TESTNUM; i++));
do
	mpirun -np 4 ./k-means/bin/KMEANS_mpi "$INPUT" "$K" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "./k-means/bin/out/mpi.txt"
done

for ((i=0; i < TESTNUM; i++));
do
	./k-means/bin/KMEANS_omp "$INPUT" "$K" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "./k-means/bin/out/omp.txt"
done
