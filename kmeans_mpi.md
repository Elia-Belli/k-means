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
