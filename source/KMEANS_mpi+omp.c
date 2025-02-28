/*
 * k-Means clustering algorithm
 *
 * MPI version
 *
 * Parallel computing (Degree in Computer Engineering)
 * 2022/2023
 *
 * Version: 1.0
 *
 * (c) 2022 Diego García-Álvarez, Arturo Gonzalez-Escribano
 * Grupo Trasgo, Universidad de Valladolid (Spain)
 *
 * This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
 * https://creativecommons.org/licenses/by-sa/4.0/
 */
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <float.h>
#include <mpi.h>
#include <omp.h>

#define MAXLINE 2000
#define MAXCAD 200

//Macros
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

#define MPI_CHECK_RETURN(value){            \
    if(value != MPI_SUCCESS){               \
        char error_str[100];                \
        int len;                            \
        MPI_Error_string(value, error_str, &len);                               \
        fprintf(stderr, "MPI Error: %s \n at line %d in file %s\n", error_str, __LINE__, __FILE__);            \
        MPI_Abort( MPI_COMM_WORLD, EXIT_FAILURE );                              \
    }       \
}
/*
Function showFileError: It displays the corresponding error during file reading.
*/
void showFileError(int error, char* filename)
{
    printf("Error\n");
    switch (error)
    {
    case -1:
        fprintf(stderr, "\tFile %s has too many columns.\n", filename);
        fprintf(stderr, "\tThe maximum number of columns has been exceeded. MAXLINE: %d.\n", MAXLINE);
        break;
    case -2:
        fprintf(stderr, "Error reading file: %s.\n", filename);
        break;
    case -3:
        fprintf(stderr, "Error writing file: %s.\n", filename);
        break;
    }
    fflush(stderr);
}

/*
Function readInput: It reads the file to determine the number of rows and columns.
*/
int readInput(char* filename, int* lines, int* samples)
{
    FILE* fp;
    char line[MAXLINE] = "";
    char* ptr;
    const char* delim = "\t";
    int contlines, contsamples = 0;

    contlines = 0;

    if ((fp = fopen(filename, "r")) != NULL)
    {
        while (fgets(line, MAXLINE, fp) != NULL)
        {
            if (strchr(line, '\n') == NULL)
            {
                return -1;
            }
            contlines++;
            ptr = strtok(line, delim);
            contsamples = 0;
            while (ptr != NULL)
            {
                contsamples++;
                ptr = strtok(NULL, delim);
            }
        }
        fclose(fp);
        *lines = contlines;
        *samples = contsamples;
        return 0;
    }
    else
    {
        return -2;
    }
}

/*
Function readInput2: It loads data from file.
*/
int readInput2(char* filename, float* data)
{
    FILE* fp;
    char line[MAXLINE] = "";
    char* ptr;
    const char* delim = "\t";
    int i = 0;

    if ((fp = fopen(filename, "rt")) != NULL)
    {
        while (fgets(line, MAXLINE, fp) != NULL)
        {
            ptr = strtok(line, delim);
            while (ptr != NULL)
            {
                data[i] = atof(ptr);
                i++;
                ptr = strtok(NULL, delim);
            }
        }
        fclose(fp);
        return 0;
    }
    else
    {
        return -2; //No file found
    }
}

/*
Function writeResult: It writes in the output file the cluster of each sample (point).
*/
int writeResult(int* classMap, int lines, const char* filename)
{
    FILE* fp;

    if ((fp = fopen(filename, "wt")) != NULL)
    {
        for (int i = 0; i < lines; i++)
        {
            fprintf(fp, "%d\n", classMap[i]);
        }
        fclose(fp);

        return 0;
    }
    else
    {
        return -3; //No file found
    }
}

/*

Function initCentroids: This function copies the values of the initial centroids, using their
position in the input data structure as a reference map.
*/
void initCentroids(const float* data, float* centroids, int* centroidPos, int samples, int K)
{
    int i;
    int idx;
    for (i = 0; i < K; i++)
    {
        idx = centroidPos[i];
        memcpy(&centroids[i * samples], &data[idx * samples], (samples * sizeof(float)));
    }
}

/*
Function euclideanDistance: Euclidean distance
This function could be modified
*/
float_t euclideanDistance(const float* point, const float* center, const int samples)
{
    float_t dist = 0.0;
    for (int i = 0; i < samples; i++)
    {
        dist += (point[i] - center[i]) * (point[i] - center[i]);
    }

    return sqrt(dist);
}

int main(int argc, char* argv[])
{
    /* 0. Initialize MPI */
    int rank, size, provided;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_SERIALIZED, &provided);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN);

    //START CLOCK***************************************
    double start, end, globalTime, localTime;
    MPI_Barrier(MPI_COMM_WORLD);
    start = MPI_Wtime();
    //**************************************************
    /*
    * PARAMETERS
    *
    * argv[1]: Input data file
    * argv[2]: Number of clusters
    * argv[3]: Maximum number of iterations of the method. Algorithm termination condition.
    * argv[4]: Minimum percentage of class changes. Algorithm termination condition.
    *          If between one iteration and the next, the percentage of class changes is less than
    *          this percentage, the algorithm stops.
    * argv[5]: Precision in the centroid distance after the update.
    *          It is an algorithm termination condition. If between one iteration of the algorithm
    *          and the next, the maximum distance between centroids is less than this precision, the
    *          algorithm stops.
    * argv[6]: Output file. Class assigned to each point of the input file.
    * */
    if (argc != 7)
    {
        fprintf(stderr, "EXECUTION ERROR K-MEANS: Parameters are not correct.\n");
        fprintf(
            stderr,
            "./KMEANS [Input Filename] [Number of clusters] [Number of iterations] [Number of changes] [Threshold] [Output data file]\n");
        fflush(stderr);
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    // Reading the input data
    // lines = number of points; samples = number of dimensions per point
    int lines = 0, samples = 0;

    int error = readInput(argv[1], &lines, &samples);
    if (error != 0)
    {
        showFileError(error, argv[1]);
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    float* data = (float*)calloc(lines * samples, sizeof(float));
    if (data == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }
    error = readInput2(argv[1], data);
    if (error != 0)
    {
        showFileError(error, argv[1]);
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    // Parameters
    int K = atoi(argv[2]);
    int maxIterations = atoi(argv[3]);
    int minChanges = (int)(lines * atof(argv[4]) / 100.0);
    float maxThreshold = atof(argv[5]);

    int* centroidPos = (int*)calloc(K, sizeof(int));
    float* centroids = (float*)calloc(K * samples, sizeof(float));

    if (centroidPos == NULL || centroids == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    // Initial centroids
    srand(0);
    int i;
    for (i = 0; i < K; i++)
        centroidPos[i] = rand() % lines;

    // Loading the array of initial centroids with the data from the array data
    // The centroids are points stored in the data array.
    initCentroids(data, centroids, centroidPos, samples, K);

    #ifdef DEBUG
    if (rank == 0)
    {
        printf("\n\tData file: %s \n\tPoints: %d\n\tDimensions: %d\n", argv[1], lines, samples);
        printf("\tNumber of clusters: %d\n", K);
        printf("\tMaximum number of iterations: %d\n", maxIterations);
        printf("\tMinimum number of changes: %d [%g%% of %d points]\n", minChanges, atof(argv[4]), lines);
        printf("\tMaximum centroid precision: %f\n", maxThreshold);
    }

    //END CLOCK*****************************************
    end = MPI_Wtime();
    localTime = end - start;
    MPI_Reduce(&localTime, &globalTime, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0)
    {
        printf("\nMemory allocation: %f seconds\n", globalTime);
        fflush(stdout);
    }
    //**************************************************
    #endif

    //START CLOCK***************************************
    MPI_Barrier(MPI_COMM_WORLD);
    start = MPI_Wtime();
    //**************************************************
    #ifdef DEBUG
    char* outputMsg = NULL;
    char line[100];

    if (rank == 0)
    {
        outputMsg = calloc(10000, sizeof(char));
        if (outputMsg == NULL)
        {
            fprintf(stderr, "Memory allocation error.\n");
            MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
        }
    }
    #endif
    // Get the number of threads that will be spawned
    const char* RAW_OMP_NUM_THREADS = getenv("OMP_NUM_THREADS");
    const int OMP_NUM_THREADS = (RAW_OMP_NUM_THREADS != NULL) ? (atoi(RAW_OMP_NUM_THREADS)) : omp_get_max_threads();

    float_t dist, minDist = FLT_MAX, maxDist = FLT_MIN;
    int it = 1, changes = 0, anotherIteration = 0;
    int cluster, j;
    int* classMap = NULL;

    // pointPerClass: number of points classified in each class
    // auxCentroids: mean of the points in each class
    // centroidsPerProcess: number of centroids assigned to each process
    // centroidsDisplacement: starting centroid position for each process
    // localAuxCentroids: local version of auxCentroid for each process
    int* centroidsPerProcess = calloc(size, sizeof(int));
    int* centroidsDispls = calloc(size, sizeof(int));
    int* pointsPerClass = (int*)calloc(K, sizeof(int));
    float* auxCentroids = (float*)calloc(K * samples, sizeof(float));
    float* localAuxCentroids = (float*)calloc(K * samples, sizeof(float));
    if (pointsPerClass == NULL || auxCentroids == NULL || localAuxCentroids == NULL || centroidsPerProcess == NULL ||
        centroidsDispls == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    MPI_Request reqs[3], req, workSplit[2];
    int *linesPerProcess = NULL, *displacementPerProcess = NULL;
    int workPerProcess = (lines / size), workReminder = (lines % size);
    int processCentroids = (K / size), centroidsReminder = (K % size);
    int startCentroidPerSamples, centroidOffsetPerSamples;
    int startLine = rank * workPerProcess;
    int lineOffset = workPerProcess;
    int startCentroid = rank * processCentroids;
    int centroidOffset = processCentroids;

    // Data to split lines between ranks
    if (rank < workReminder)
    {
        startLine += rank;
        lineOffset++;
    }
    else
    {
        startLine += workReminder;
    }

    // Data to split centroids between ranks
    if (rank < centroidsReminder)
    {
        startCentroid += rank;
        centroidOffset++;
    }
    else
    {
        startCentroid += centroidsReminder;
    }

    startCentroidPerSamples = startCentroid * samples;
    centroidOffsetPerSamples = centroidOffset * samples;

    MPI_CHECK_RETURN(
        MPI_Iallgather(&startCentroidPerSamples, 1, MPI_INT, centroidsDispls, 1, MPI_INT, MPI_COMM_WORLD, &reqs[0])
    )
    MPI_CHECK_RETURN(
        MPI_Iallgather(&centroidOffsetPerSamples, 1, MPI_INT, centroidsPerProcess, 1, MPI_INT, MPI_COMM_WORLD, &reqs[1])
    )

    if (rank == 0)
    {
        linesPerProcess = calloc(size, sizeof(int));
        displacementPerProcess = calloc(size, sizeof(int));
        classMap = calloc(lines, sizeof(int));

        if (linesPerProcess == NULL || displacementPerProcess == NULL || classMap == NULL)
        {
            fprintf(stderr, "Memory allocation error.\n");
            MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
        }
    }

    MPI_CHECK_RETURN(
        MPI_Igather(&startLine, 1, MPI_INT, displacementPerProcess, 1, MPI_INT, 0, MPI_COMM_WORLD, &workSplit[0])
    )
    MPI_CHECK_RETURN(
        MPI_Igather(&lineOffset, 1, MPI_INT, linesPerProcess, 1, MPI_INT, 0, MPI_COMM_WORLD, &workSplit[1])
    )

    // Each rank will compute only his part of classMap
    int* localClassMap = calloc(sizeof(int), lineOffset);
    if (localClassMap == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    MPI_CHECK_RETURN(MPI_Waitall(2, reqs, MPI_STATUS_IGNORE));

    # pragma omp parallel num_threads(OMP_NUM_THREADS) private(i, j, cluster, dist, minDist)
    {
        do
        {
            // 1. Assign each point to a class and count the elements in each class
            #pragma omp for reduction(+:changes, pointsPerClass[:K])
            for (i = 0; i < lineOffset; i++)
            {
                cluster = 1, minDist = FLT_MAX;
                for (j = 0; j < K; j++)
                {
                    dist = euclideanDistance(&data[(startLine + i) * samples], &centroids[j * samples], samples);

                    if (dist < minDist)
                    {
                        minDist = dist;
                        cluster = j + 1;
                    }
                }
                if (localClassMap[i] != cluster)
                {
                    changes++;
                    localClassMap[i] = cluster;
                }

                pointsPerClass[cluster - 1]++;
            }

            # pragma omp single nowait
            {
                MPI_CHECK_RETURN(
                    MPI_Iallreduce(MPI_IN_PLACE, pointsPerClass, K, MPI_INT, MPI_SUM, MPI_COMM_WORLD, &req)
                );
                MPI_CHECK_RETURN(
                    MPI_Iallreduce(MPI_IN_PLACE, &changes, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD, &reqs[0])
                );
            }

            // 2. Compute the coordinates mean of all the point in the same class
            # pragma omp for reduction(+:localAuxCentroids[:K*samples])
            for (i = 0; i < lineOffset; i++)
            {
                cluster = localClassMap[i] - 1;
                for (j = 0; j < samples; j++)
                {
                    localAuxCentroids[cluster * samples + j] += data[(startLine + i) * samples + j];
                }
            }

            #pragma omp single
            {
                MPI_CHECK_RETURN(
                    MPI_Allreduce(MPI_IN_PLACE, localAuxCentroids, K * samples, MPI_FLOAT, MPI_SUM, MPI_COMM_WORLD)
                );
                MPI_CHECK_RETURN(MPI_Wait(&req, MPI_STATUS_IGNORE));
            }

            #pragma omp for
            for (i = 0; i < centroidOffset; i++)
            {
                cluster = startCentroid + i;
                for (j = 0; j < samples; j++)
                {
                    localAuxCentroids[cluster * samples + j] /= pointsPerClass[cluster];
                }
            }

            # pragma omp single nowait
            {
                MPI_CHECK_RETURN(MPI_Iallgatherv(
                    localAuxCentroids + startCentroid * samples, centroidOffsetPerSamples, MPI_FLOAT,
                    auxCentroids, centroidsPerProcess, centroidsDispls,
                    MPI_FLOAT, MPI_COMM_WORLD, &reqs[2]));
            }

            // 3. Compute the maximum movement of a centroid compared to its previous position
            # pragma omp for reduction(max:maxDist)
            for (i = 0; i < centroidOffset; i++)
            {
                dist = euclideanDistance(
                    &centroids[(startCentroid + i) * samples],
                    &localAuxCentroids[(startCentroid + i) * samples],
                    samples
                );

                if (dist > maxDist)
                {
                    maxDist = dist;
                }
            }

            #pragma omp single
            {
                MPI_CHECK_RETURN(
                    MPI_Iallreduce(MPI_IN_PLACE, &maxDist, 1, MPI_FLOAT, MPI_MAX, MPI_COMM_WORLD, &reqs[1])
                );

                memset(pointsPerClass, 0, K * sizeof(int));
                memset(localAuxCentroids, 0.0, K * samples * sizeof(float));

                MPI_CHECK_RETURN(MPI_Waitall(2, reqs, MPI_STATUS_IGNORE));

                #ifdef DEBUG
                if(rank == 0)
                {
                    sprintf(line, "\n[%d] Cluster changes: %d\tMax. centroid distance: %f", it, changes, maxDist);
                    outputMsg = strcat(outputMsg, line);
                }
                #endif

                anotherIteration = (changes > minChanges) && (it < maxIterations) && (maxDist > maxThreshold);
                changes = 0;
                maxDist = FLT_MIN;
                it++;

                MPI_CHECK_RETURN(MPI_Wait(&reqs[2], MPI_STATUS_IGNORE));
                memcpy(centroids, auxCentroids, K * samples * sizeof(float));
            }
        }
        while (anotherIteration);
    }
    it--;
    // 5. Gather to the root process all the information that will be written in the output file
    MPI_CHECK_RETURN(MPI_Waitall(2, workSplit, MPI_STATUS_IGNORE));
    MPI_CHECK_RETURN(MPI_Igatherv(
        localClassMap, lineOffset,
        MPI_INT, classMap, linesPerProcess,
        displacementPerProcess, MPI_INT, 0, MPI_COMM_WORLD, &req
    ));

    //END CLOCK*****************************************
    end = MPI_Wtime();
    localTime = end - start;
    MPI_Reduce(&localTime, &globalTime, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0)
    {
        #ifdef DEBUG
        // Print to stdout all the info about this run
        printf("%s", outputMsg);
        printf("\nComputation: %f seconds", globalTime);
        if (changes <= minChanges)
        {
            printf("\n\nTermination condition:\nMinimum number of changes reached: %d [%d]", changes, minChanges);
        }
        else if (it >= maxIterations)
        {
            printf("\n\nTermination condition:\nMaximum number of iterations reached: %d [%d]", it, maxIterations);
        }
        else
        {
            printf("\n\nTermination condition:\nCentroid update precision reached: %g [%g]", maxDist, maxThreshold);
        }
        free(outputMsg);
        #else
        printf("%f", globalTime);
        #endif
        fflush(stdout);
    }
    //**************************************************
    //START CLOCK***************************************
    MPI_Barrier(MPI_COMM_WORLD);
    start = MPI_Wtime();
    //**************************************************


    if (rank == 0)
    {
        MPI_Wait(&req, MPI_STATUS_IGNORE);
        error = writeResult(classMap, lines, argv[6]);
        if (error != 0)
        {
            showFileError(error, argv[6]);
            MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
        }

        free(linesPerProcess);
        free(displacementPerProcess);
        free(classMap);
    }

    //Free memory
    free(centroidsPerProcess);
    free(centroidsDispls);
    free(pointsPerClass);
    free(auxCentroids);
    free(localAuxCentroids);
    free(localClassMap);
    free(data);
    free(centroidPos);
    free(centroids);
    MPI_Request_free(&req);
    MPI_Request_free(&reqs[0]);
    MPI_Request_free(&reqs[1]);
    MPI_Request_free(&reqs[2]);
    MPI_Request_free(&workSplit[0]);
    MPI_Request_free(&workSplit[1]);
    //END CLOCK*****************************************
    #ifdef DEBUG
    end = MPI_Wtime();
    localTime = end - start;
    MPI_Reduce(&localTime, &globalTime, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0)
    {
        printf("\n\nMemory deallocation: %f seconds\n", globalTime);
        fflush(stdout);
    }
    #endif
    //***************************************************/
    MPI_Finalize();
    return 0;
}
