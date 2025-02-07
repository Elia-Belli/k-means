#!/usr/bin/env bash
# ---------------------------------------------------------
# Change only this section of the file to modify test runs
TEST_DIR="./test_files/"
OUT_DIR="./bin/out/"
TEST_RESULTS="tests/"

MPI_PROCESSES=32
OMP_NUM_THREADS=32
MPI_PROCESSES_COMBINED=8 # only in local
OMP_NUM_THREADS_COMBINED=32 # only in local

RUN_SEQUENTIAL_TESTS=false
RUN_MPI_TESTS=false
RUN_OMP_TESTS=false
RUN_CUDA_TESTS=false
RUN_MPI_OMP_TESTS=true
RUN_MPI_PARALLEL_TESTS=true

TEST_RUN=1
INPUT_NUM=5
INPUT=("${TEST_DIR}input2D.inp" "${TEST_DIR}input2D2.inp" "${TEST_DIR}input10D.inp" "${TEST_DIR}input20D.inp" "${TEST_DIR}input100D.inp" "${TEST_DIR}input100D2.inp")
K=(100 8 100 100 100 100)
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01
# ---------------------------------------------------------