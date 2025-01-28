TESTNUM=20

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

for ((i = 0; i < TESTNUM; i++));
do
    condor_submit job.sub -append "executable = $MPI_EXE" -append "arguments = $INPUT $K $ITER $MIN_CHANGES $MAX_DIST k-means/bin/out/mpi.txt" -append 'requirements = (Machine == "node113.di.rm1")'

    cat logs/job.out >> "logs/test_mpi.txt" 
done


for ((i = 0; i < TESTNUM; i++));
do
    condor_submit job.sub -append "executable = $OMP_EXE" -append "arguments = $INPUT $K $ITER $MIN_CHANGES $MAX_DIST k-means/bin/out/omp.txt" -append 'requirements = (Machine == "node113.di.rm1")'
    cat logs/job.out >> "logs/test_omp.txt" 
done
