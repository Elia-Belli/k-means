# SEQUENTIAL K-MEANS Implementation

## Input
1. Con `int readInput(char* filename, int *lines, int *samples)` apre il file per contare il numero di punti e il numero di dimensioni, che salva rispettivamente in `lines` e `samples`

2. Con `int readInput2(char* filename, float* data)` legge effettivamente il contenuto del file, salvando i dati linearizzati in `data` (di dimensione `lines * samples * sizeof(float)`) 

3. Lettura parametri da `argv` : 
    int K: numero di centroidi
    Condizioni di terminazione:
        1. int maxIterations: al cicli `maxIterations` termina
        2. int minChanges: se al massimo `minChanges` centroidi cambiano cluster termina 
        3. maxThreshold: se i centroidi (tutti o almeno uno?) non si spostano almeno di `maxThreshold` termina
    

## Allocazione

Alloca:
- `int *CentroidPos`: per salvare a quale punto corrispondono le coordinate iniziali di ogni centroide (in teoria, usato solo all'inizio)
- `float *centroids`: per salvare le coordinate di tutti i centroidi
- `int *classMap`: per salvare il cluster di appartenenza (da 1 a K) di ogni punto

>[!bug] Stampa delle iterazioni (buffer overflow)
> Per `outputMsg` viene allocato uno spazio di memoria fisso di `10.000 * sizeof(char)` , siccome la stampa avviene solo alla fine se la condizione terminante sono i cicli e `maxIterations > 150` potrebbe non esserci abbastanza spazio per memorizzarli tutti, quindi crasha!

- `int *pointsPerClass`: per salvare il numero di punti appartenenti ad ogni cluster (ad ogni iterazione)
- `float *auxCentroids`: per salvare le nuove posizioni dei centroidi (ad ogni iterazione)
- `float *distCentroids`: per salvare le distanze di un punto da ogni centroide, in modo da assegnarlo al cluster giusto (ad ogni iterazione, per ogni punto)

## Inizializzazione

1. Seleziona random i punti per `*CentroidPos`
2. Chiama `initCentroid(const float *data, float* centroids, int* centroidPos, ...)` che copia, secondo la mappa `CentroidPos`, le coordinate dei punti selezionati da `data` a `centroids` 

## Algoritmo

Ripetere finché non si raggiunge una delle condizioni di terminazione:
1. Per ogni punto:
    - Calcolare la distanza da ogni centroide
    - Selezionare la minore, e aggiornare la classe di appartenenza se necessario (incrementando anche `changes` per la condizione `minChanges`)
2. Calcolare `pointsPerClass` per questa iterazione
3. Per ogni centroide:
    - Calcolare la sua nuova posizione in `auxCentroids`, come media di tutti i punti che appartengono alla sua classe
    - Calcolare la differenza tra la nuova e la vecchia distanza (per la condizione `maxThreshold`)
4. Copiare `auxCentroids` in `centroids`
5. Controllare le condizioni di terminazione

## Output e Deallocazione

- Stampa dati sulle iterazioni, salvati su `outputMsg`
- Stampa timing della computazione
- Stampa condizione di terminazione: `valore` `[valore di terminazione]`
- Stampa `classMap` su file con `writeResult(...)`  (!!!Ricordiamo di settare lo stesso seed per confrontare i risultati col sequenziale, e naturalmente usare gli stessi valori di terminazione)