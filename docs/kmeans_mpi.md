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

1. I punti possono essere partizionati tra i rank per il calcolo delle distanze dai centroidi: usiamo un array `classMapLocal` per i soli punti elaborati, si aggiorna `changes` localmente,  poi si fa una AllReduce(+) per `changes` (tutti i rank potranno controllare `changes > minChanges`).

2. Dobbiamo fare una scelta, da qui l'algoritmo può prendere due strade **(1)** o **(2)**
- (1) Fare una `AllGather()` per `classMap` e procedere similmente al sequenziale: possiamo fare una `IallGather()` per `classMap` e nel mentre azzerare `pointPerClass` e `auxCentroids`, calcolare una parte di `pointPerClass` con `localMap` e poi si fa una `AllReduce(+)` su `pointPerClass`.
- (2) Continuare localmente, ogni volta che calcoliamo la `class` di appartenenza di un punto aggiorniamo `pointPerClass[class]` e sommiamo le sue coordinate in `auxCentroids[class]` : l'azzeramento si può fare a inizio o fine iterazione. Eventualmente servirà fare la Gather per stampare l'output almeno alla fine.

3. Calcolo nuove coordinate dei Centroidi:
- (1) Si possono dividere i centroidi tra i rank per il calcolo di `auxCentroids`: a ognuno è nota la `classMap` però deve scorrela tutta per trovare i punti nelle classi dei centroidi elaborati da lui, in questo modo fa la somma, al termine della somma divide le coordinate del centroide per il `pointPerClass` corrispondente già calcolato.
- (2) Ogni rank possiede la somma parziale delle nuove coordinate dei centroidi e dei punti per classe, possiamo fare due `Allreduce(+)`, una su `auxCentroids` e una su `pointPerClass`, completando le somme, siamo pronti a dividere le coordinate dei centroidi per il `pointPerClass` corrispondente (-la divisione non è parallelizzata).

4. Calcolo spostamenti dei Centroidi:
- (1) Ogni rank scorre sui propri centroidi, calcolando lo spostamento di ognuno e aggiornando `maxDist` man mano, alla fine si fa una `Allreduce(max)` su `maxDist`.
- (2) Tutti i rank conoscono già tutte le nuove coordinate, si parallelizza il calcolo della `maxDist` e poi si fa una `Allreduce(max)` su `maxDist`.

5. Aggiornamento posizioni Centroidi correnti:
- (1) I rank conoscono ancora solamente le coordinate dei centroidi da loro calcolati, serve una `AllGather` da `auxCentroids` a `centroids`
- (2) I rank conoscono già tutte le coordinate, ognuno esegue la `memcpy` di `auxCentroids` su `centroids`

6. Ogni rank ha già raccolto `changes` e `maxDist`, allora controlla le condizioni di terminazione, se non termina ha già tutti i dati per la prossima iterazione pronti
- Alternativamente, se vogliamo che solo il rank 0 faccia il controllo delle condizioni al posto delle `AllReduce()` si possono usare delle `Reduce()` sul rank 0, ma va comunicato l'esito a tutti gli altri rank: il rank 0 fa il controllo e avvisa gli altri rank dell'esito con una `Bcast()` gli altri attendono con una `Barrier()`.
Alla fine una `AllReduce()` è concettualmente una `Reduce()` + `Bcast()` ma implementata in modo più efficiente, quindi eviterei.
