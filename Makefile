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
ARCH=-arch=sm_50
FMAD=-fmad=false

# Targets to build
OBJS = 	KMEANS_seq\
 		KMEANS_mpi\
 		KMEANS_omp\
 		KMEANS_mpi+omp\
 		KMEANS_cuda\

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

# seq
KMEANS_seq: ./source/KMEANS.c
	$(CC) $(FLAGS) $(DEBUG) $< $(LIBS) -o ./bin/$@

# mpi
KMEANS_mpi: ./source/KMEANS_mpi.c
	$(MPICC) $(FLAGS) $(DEBUG) $< $(LIBS) -o ./bin/$@

# omp
KMEANS_omp: ./source/KMEANS_omp.c
	$(CC) $(FLAGS) $(DEBUG) $(OMPFLAG) $< $(LIBS) -o ./bin/$@

# cuda
KMEANS_cuda: ./source/KMEANS_cuda.cu
	$(CUDACC) $(DEBUG) $< $(LIBS) $(ARCH) $(FMAD) -o ./bin/$@

# mpi + omp
KMEANS_mpi+omp: ./source/KMEANS_mpi+omp.c
	$(MPICC) $(FLAGS) $(DEBUG) $(OMPFLAG) $< $(LIBS) -o ./bin/$@

# utils
compare: ./source/utils/compare.c
	$(CC) $(FLAGS) $< -o ./bin/$@

test_generator: ./source/utils/test_generator.c
	$(CC) $(FLAGS) $(DEBUG) $< -o ./bin/$@

# Remove the target files
clean:
	rm -rf ./bin/KMEANS_* ./bin/compare ./bin/test_generator ./bin/out/*

# Compile in debug mode
debug:
	make DEBUG="-D DEBUG -g" FLAGS= all

