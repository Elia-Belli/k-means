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
RUN_CUDA_TESTS=true
RUN_MPI_OMP_TESTS=false
RUN_MPI_PARALLEL_TESTS=false

TEST_RUN=10
INPUT_NUM=6
INPUT=("${TEST_DIR}input2D2.inp" "${TEST_DIR}input2D.inp" "${TEST_DIR}input10D.inp" "${TEST_DIR}input20D.inp" "${TEST_DIR}input100D.inp" "${TEST_DIR}input100D2.inp")
K=(100 8 100 100 100 100)
ITER=150
MIN_CHANGES=0.01
MAX_DIST=0.01

STRONG_SCALING_THREADS=(1 2 4 8 12 16 20 24 28 32)
STRONG_SCALING_INPUT=5

INPUT_WEAK=("${TEST_DIR}input3125x100.inp" "${TEST_DIR}input6250x100.inp" "${TEST_DIR}input12500x100.inp" "${TEST_DIR}input25000x100.inp" "${TEST_DIR}input37500x100.inp" "${TEST_DIR}input50000x100.inp" "${TEST_DIR}input62500x100.inp" "${TEST_DIR}input75000x100.inp" "${TEST_DIR}input87500x100.inp")
WEAK_SCALING_THREADS=(1 2 4 8 12 16 20 24 28)

INPUT_CUDA=("${TEST_DIR}input3125x100.inp" "${TEST_DIR}input6250x100.inp" "${TEST_DIR}input12500x100.inp" "${TEST_DIR}input25000x100.inp" "${TEST_DIR}input37500x100.inp" "${TEST_DIR}input50000x100.inp" "${TEST_DIR}input62500x100.inp" "${TEST_DIR}input75000x100.inp" "${TEST_DIR}input87500x100.inp" "${TEST_DIR}input100D2.inp" "${TEST_DIR}input250000x100.inp" "${TEST_DIR}input500000x100.inp" "${TEST_DIR}input1000000x100.inp")

NODES_STRONG_MPI_OMP=(2 4)
INPUT_STRONG_MPI_OMP=("${TEST_DIR}input1000000x100.inp")

NODES_WEAK_MPI_OMP=(1 2 4 8 16)
INPUT_NUM=(0 0 1 0 0 2 0 0 0 3 0 0 0 0 0 0 0 4)
INPUT_WEAK_MPI_OMP=("${TEST_DIR}input31250x100.inp" "${TEST_DIR}input62500x100.inp" "${TEST_DIR}input125000x100.inp" "${TEST_DIR}input250000x100.inp" "${TEST_DIR}input500000x100.inp" "${TEST_DIR}input1000000x100.inp")
# ---------------------------------------------------------