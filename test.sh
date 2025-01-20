TESTNUM=10

rm -r "test_log.txt"
make KMEANS_omp_fede
make KMEANS_omp_fede_old

echo "Esecuzione prima batteria di test" >> "test_log_b1.txt"

for ((i = 0; i < TESTNUM; i++));
do
  ./bin/KMEANS_omp_fede "./test_files/input100D2.inp" 22347 10000 0.1 0.1 "./bin/out/KMEANS_big_omp_fede.txt" >> "test_log_b1.txt"
done

echo "Esecuzione seconda batteria di test\n\n\n" >> "test_log_b2.txt"

for ((i = 0; i < TESTNUM; i++));
do
  ./bin/KMEANS_omp_fede_old "./test_files/input100D2.inp" 22347 10000 0.1 0.1 "./bin/out/KMEANS_big_omp_fede_old.txt" >> "test_log_b2.txt"
done

