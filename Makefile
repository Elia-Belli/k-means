#
# K-means 
#
# Parallel computing (Degree in Computer Engineering)
# 2022/2023
#
# (c) 2023 Diego Garcia-Alvarez and Arturo Gonzalez-Escribano
# Grupo Trasgo, Universidad de Valladolid (Spain)
#

# Compilers
CC=gcc
OMPFLAG=-fopenmp
MPICC=mpicc
CUDACC=nvcc

# Flags for optimization and libs
FLAGS=-O3 -Wall
LIBS=-lm

# Targets to build
OBJS=KMEANS_seq KMEANS_omp KMEANS_mpi KMEANS_cuda KMEANS++ compare test_generator

# Rules. By default show help
help:
	@echo
	@echo "K-means clustering method"
	@echo
	@echo "Group Trasgo, Universidad de Valladolid (Spain)"
	@echo
	@echo "make KMEANS_seq	Build only the sequential version"
	@echo "make cKMEANS_omp	Build only the OpenMP version"
	@echo "make KMEANS_mpi	Build only the MPI version"
	@echo "make KMEANS_cuda	Build only the CUDA version"
	@echo
	@echo "make all	Build all versions (Sequential, OpenMP)"
	@echo "make debug	Build all version with demo output for small surfaces"
	@echo "make clean	Remove targets"
	@echo

all: $(OBJS)

KMEANS_seq: KMEANS.c
	$(CC) $(FLAGS) $(DEBUG) $< $(LIBS) -o ./bin/$@

KMEANS++: KMEANS++.c
	$(CC) -g $(FLAGS) $(DEBUG) $< $(LIBS) -o ./bin/$@

KMEANS_omp: KMEANS_omp.c
	$(CC) $(FLAGS) $(DEBUG) $(OMPFLAG) $< $(LIBS) -o ./bin/$@

KMEANS_mpi: KMEANS_mpi.c
	$(MPICC) $(FLAGS) $(DEBUG) $< $(LIBS) -o ./bin/$@

#-Xptxas -v : to see registers
KMEANS_cuda: KMEANS_cuda.cu
	$(CUDACC) -Wno-deprecated-gpu-targets -arch=sm_50 -lm $< -o ./bin/$@			

compare: compare.c
	$(CC) $(FLAGS) $< -o ./bin/$@

KMEANS_mpi_elia: ./mpi/KMEANS_mpi_elia.c
	$(MPICC) $(FLAGS) $(DEBUG) $< $(LIBS) -o ./bin/$@

KMEANS_mpi_fede: ./mpi/KMEANS_mpi_fede.c
	$(MPICC) $(FLAGS) $(DEBUG) $< $(LIBS) -o ./bin/$@

KMEANS_omp_fede: ./openmp/KMEANS_omp_fede.c
	$(CC) $(FLAGS) $(DEBUG) $(OMPFLAG) $< $(LIBS) -o ./bin/$@

KMEANS_omp_fede_old: ./openmp/KMEANS_omp_fede_old.c
	$(CC) $(FLAGS) $(DEBUG) $(OMPFLAG) $< $(LIBS) -o ./bin/$@

test_generator: ./test_files/test_generator.c
	$(CC) $(FLAGS) $(DEBUG) $< -o ./bin/$@

# Remove the target files
clean:
	rm -rf $(OBJS)

# Compile in debug mode
debug:
	make DEBUG="-DDEBUG -g" FLAGS= all

