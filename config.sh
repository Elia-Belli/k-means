#!/usr/bin/env bash
# ---------------------------------------------------------
# Change only this section of the file to modify test runs
TEST_DIR="./test_files/"
OUT_DIR="./bin/out/"
TEST_RESULTS="./tests/"

MPI_PROCESSES=32
OMP_NUM_THREADS=32
MPI_PROCESSES_COMBINED=8
OMP_NUM_THREADS_COMBINED=32
SCALING_THREADS=(1 2 4 8 12 16 20 24 28 32)

RUN_SEQUENTIAL_TESTS=false
RUN_MPI_TESTS=true
RUN_OMP_TESTS=true
RUN_CUDA_TESTS=true
RUN_MPI_OMP_TESTS=true
RUN_MPI_PARALLEL_TESTS=false

TEST_RUN=1
INPUT=("${TEST_DIR}input3125x100.inp" "${TEST_DIR}input6250x100.inp" "${TEST_DIR}input12500x100.inp" "${TEST_DIR}input25000x100.inp" "${TEST_DIR}input37500x100.inp" "${TEST_DIR}input50000x100.inp" "${TEST_DIR}input62500x100.inp" "${TEST_DIR}input75000x100.inp" "${TEST_DIR}input87500x100.inp")
K=(100 100 100 100 100 100 100 100 100)
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01

# ---------------------------------------------------------
