#!/usr/bin/bash

export OMP_NUM_THREADS=32

TESTNUM=1
INPUT="./k-means/test_files/input100D2.inp"
K=10
ITER=10
MIN_CHANGES=0.01
MAX_DIST=0.01

MPI_EXE=./k-means/bin/KMEANS_mpi
OMP_EXE=./k-means/bin/KMEANS_omp
CUDA_EXE=./k-means/bin/KMEANS_cuda

cd k-means
make compare
make KMEANS_seq
make KMEANS_mpi
make KMEANS_omp
make KMEANS_cuda
cd ..

rm "logs/test_mpi.txt"
rm "logs/test_omp.txt"
rm "logs/test_cuda.txt"

./k-means/bin/KMEANS_seq "$INPUT" "$K" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "./k-means/bin/out/seq.txt"
echo "---------------------------------" >> ./logs/job.out


for ((i=0; i < TESTNUM; i++));
do
    mpirun -np 32 ./k-means/bin/KMEANS_mpi "$INPUT" "$K" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "./k-means/bin/seq.txt"
    ./k-means/bin/compare "./k-means/bin/out/seq.txt" "./k-means/bin/out/mpi.txt"
    echo "---------------------------------" >> ./logs/job.out
done


for ((i=0; i < TESTNUM; i++));
do
    ./k-means/bin/KMEANS_omp "$INPUT" "$K" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "./k-means/bin/out/omp.txt"
    ./k-means/bin/compare "./k-means/bin/out/seq.txt" "./k-means/bin/out/omp.txt"
    echo "---------------------------------" >> ./logs/job.out
done


for ((i=0; i < TESTNUM; i++));
do
	./k-means/bin/KMEANS_cuda "$INPUT" "$K" "$ITER" "$MIN_CHANGES" "$MAX_DIST" "./k-means/bin/out/cuda.txt"
    ./k-means/bin/compare "./k-means/bin/out/seq.txt" "./k-means/bin/out/cuda.txt"
    echo "---------------------------------" >> ./logs/job.out
done

