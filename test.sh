TESTNUM=20

rm test_log_b1.txt
rm test_log_b2.txt
make KMEANS_omp_fede
make KMEANS_omp_fede_old

export OMP_NUM_THREADS=8

echo "Esecuzione prima batteria di test" >> "test_log_b1.txt"


for ((i = 0; i < TESTNUM; i++));
do
    #./bin/KMEANS_omp_fede "./test_files/input100D2.inp" 10000 150 0.1 0.1 "./bin/out/KMEANS_big_omp_fede.txt" >> "test_log_b1.txt"
    ./bin/KMEANS_omp_fede "./test_files/input20D.inp" 50 150 0.01 0.01 "./bin/out/KMEANS_small_omp_fede.txt" >> "test_log_b1.txt"
done


echo "Esecuzione seconda batteria di test\n\n\n" >> "test_log_b2.txt"

for ((i = 0; i < TESTNUM; i++));
do
    #./bin/KMEANS_omp_fede_old "./test_files/input100D2.inp" 10000 150 0.1 0.1 "./bin/out/KMEANS_big_omp_fede_old.txt" >> "test_log_b2.txt"
    ./bin/KMEANS_omp_fede_old "./test_files/input20D.inp" 50 150 0.01 0.01 "./bin/out/KMEANS_small_omp_fede_old.txt" >> "test_log_b2.txt"
done



# output di new (batteria 1) leggermente differente su: "./test_files/input20D.inp" 50 150 0.01 0.01