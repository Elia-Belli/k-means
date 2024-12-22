# MPI K-MEANS Implementation

## Input 
Lettura file analoga al [sequenziale](kmeans_seq.md) ma all'interno di `MPI_Init()`

Lettura parametri da `argv` (non modificabile) : quindi i parametri sono visibili a tutti i processi senza bisogno di Bcast 

>[!question] Che valori dovremmo utilizzare per le condizioni di terminazione?
> Abbiamo già i benchmark da fare sulla performance al crescere di `K`.
> Limitandoci ai `test_files` forniti per lo scaling rispetto alla dimensione dell'input, possiamo scegliere delle condizioni di terminazione ragionevoli per ognuno oppure fisse per tutti. 

## Allocazione
Allocazione come nel [sequenziale](kmeans_seq.md), tutti i processi allocano tutto

## Inizializzazione
Nella sezione NON MODIFICABILE tutti i rank eseguono la lettura dell'input: quindi non serve una Bcast iniziale

## Algoritmo
**Obiettivo**: identificare le sezioni parallelizabili

1. I punti possono essere partizionati tra i rank per il calcolo delle distanze dai centroidi: se la classe di un punto  cambia vanno aggiornate `classMap` e `changes`, conviene avere una `classMapLocal` per i soli punti elaborati e un contatore `changesLocal`.
2. Ogni rank può calcolare localmente i punti per classe in un array `pointPerClassLocal`, poi si fanno una `AllReduce(+)` per `pointPerClass` ed una `AllReduce(+)` per `changes` : ogni rank potrà controllare la condizione `minChanges` a fine iterazione (?necessario controllino tutti?)
3. I centroidi possono essere partizionati tra i rank per il ricalcolo delle posizioni: per ogni centroide il rank relativo calcola le nuove coordinate in una parte di `auxCentroids` e aggiorna `maxDist` localmente così ogni rank potrà controllare la condizione `maxThreshold` a fine iterazione (?necessario controllino tutti?)
4. Elaborati tutti i centroidi si esegue una `AllReduce(max)` per `maxDist`, poi si copia `auxCentroids` in `centroids` localmente e si esegue una `AllGather()` per `centroids` in modo che tutti i rank abbiano le nuove posizioni dei centroidi.
5. Ogni rank controlla le condizioni di temrmizione, se non termina ha già tutti i dati per la prossima iterazione pronti

5. (Alternativa) Se vogliamo che solo il rank 0 faccia il controllo delle condizioni al posto delle `AllReduce()` si possono usare delle `Reduce()` sul rank 0, ma va comunicato l'esito a tutti gli altri rank: il rank 0 fa il controllo e avvisa gli altri rank dell'esito con una `Bcast()` gli altri attendono con una `Barrier()`.
Alla fine una `AllReduce()` è concettualmente una `Reduce()` + `Bcast()` ma implementata in modo più efficiente, quindi non userei la .5 (alt.)