#!/usr/bin/env bash

for((i = 0; i < 17; i++))
    do
        ./bin/KMEANS_seq "./test_files/input31250x100.inp" 100 150 0.01 0.01 "./bin/out/seq.txt" >> ./tests/seq_31250.txt
        echo "" >> ./tests/seq_31250.txt

        ./bin/KMEANS_seq "./test_files/input62500x100.inp" 100 150 0.01 0.01 "./bin/out/seq.txt" >> ./tests/seq_62500.txt
        echo "" >> ./tests/seq_62500.txt

        ./bin/KMEANS_seq "./test_files/input125000x100.inp" 100 150 0.01 0.01 "./bin/out/seq.txt" >> ./tests/seq_125000.txt
        echo "" >> ./tests/seq_125000.txt
    done