#!/usr/bin/env bash

rm ./tests/seq_250k.txt ./tests/seq_500k.txt ./tests/seq_1kk.txt

for((i = 0; i < 20; i++))
    do
        ./bin/KMEANS_seq "./test_files/input250000x100.inp" 100 150 0.01 0.01 "./bin/out/seq.txt" >> ./tests/seq_250k.txt
        echo "" >> ./tests/seq_250k.txt

        ./bin/KMEANS_seq "./test_files/input500000x100.inp" 100 150 0.01 0.01 "./bin/out/seq.txt" >> ./tests/seq_500k.txt
        echo "" >> ./tests/seq_500k.txt

        ./bin/KMEANS_seq "./test_files/input1000000x100.inp" 100 150 0.01 0.01 "./bin/out/seq.txt" >> ./tests/seq_1kk.txt
        echo "" >> ./tests/seq_1kk.txt
    done