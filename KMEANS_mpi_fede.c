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

#define MAXLINE 2000
#define MAXCAD 200

//Macros
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

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
float euclideanDistance(const float* point, const float* center, const int samples)
{
    float dist = 0.0;
    for (int i = 0; i < samples; i++)
    {
        dist += (point[i] - center[i]) * (point[i] - center[i]);
    }

    dist = sqrt(dist);
    return dist;
}

float squaredDistance(const float* point, const float* center, const int samples)
{
    float dist = 0.0;
    for (int i = 0; i < samples; i++)
    {
        dist += (point[i] - center[i]) * (point[i] - center[i]);
    }
    return dist;
}

int pointClassMapping(
    const int start, const int lines, int* classMap, int* pointsPerClass,
    const float* data, const float* centroids, const int samples, const int K
)
{
    int class, changes = 0;
    float dist, minDist;

    for (int i = 0; i < lines; i++)
    {
        class = 1, minDist = FLT_MAX;
        for (int j = 0; j < K; j++)
        {
            dist = squaredDistance(&data[(start + i) * samples], &centroids[j * samples], samples);
            if (dist < minDist)
            {
                minDist = dist, class = j + 1;
            }
        }
        if (classMap[i] != class)
        {
            changes++;
            classMap[i] = class;
        }

        pointsPerClass[classMap[i] - 1]++;
    }

    return changes;
}


int main(int argc, char* argv[])
{
    /* 0. Initialize MPI */
    MPI_Init(&argc, &argv);
    int rank, size;
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
    //START CLOCK***************************************
    MPI_Barrier(MPI_COMM_WORLD);
    start = MPI_Wtime();
    //**************************************************
    char* outputMsg = (char*)calloc(10000, sizeof(char));
    char line[100];

    int it = 0, changes = 0;
    float distCentroids, maxDist;

    //pointPerClass: number of points classified in each class
    //auxCentroids: mean of the points in each class
    int* pointsPerClass = (int*)malloc(K * sizeof(int));
    float* auxCentroids = (float*)malloc(K * samples * sizeof(float));
    if (pointsPerClass == NULL || auxCentroids == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    /*
     *
     * START HERE: DO NOT CHANGE THE CODE ABOVE THIS POINT
     *
     */

    int* linesPerProcess;
    int* displacementPerProcess;
    int* classMap;

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

        for (i = 0; i < size; i++)
        {
            linesPerProcess[i] = (i == (size - 1))
                                        ? (lines / size) + lines % size
                                        : (lines / size);
            displacementPerProcess[i] = i * (lines / size);
        }
    }

    MPI_Request reqs[2], req;
    int startLine, lineOffset, startCentroid, centroidOffset;
    startLine = rank * (lines / size);
    lineOffset = (rank == (size - 1))
                     ? (lines / size) + lines % size
                     : (lines / size);
    startCentroid = rank * (K / size);
    centroidOffset = (rank == (size - 1))
                         ? (K / size) + K % size
                         : (K / size);

    int* localClassMap = calloc(sizeof(int), lineOffset);
    if (localClassMap == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    memset(pointsPerClass, 0, K * sizeof(int));
    memset(auxCentroids, 0.0, K * samples * sizeof(float));

    do
    {
        it++;

        // 1. Assign each point to a class and count the elements in each class
        changes = pointClassMapping(
            startLine, lineOffset,
            localClassMap, pointsPerClass,
            data, centroids, samples, K
        );

        // 2. Compute the coordinates mean of all the point in the same class
        MPI_Iallreduce(MPI_IN_PLACE, &changes, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD, &reqs[0]);
        MPI_Iallreduce(MPI_IN_PLACE, pointsPerClass, K, MPI_INT, MPI_SUM, MPI_COMM_WORLD, &req);

        for (i = 0; i < lineOffset; i++)
        {
            for (int j = 0; j < samples; j++)
            {
                auxCentroids[(localClassMap[i] - 1) * samples + j] += data[(startLine + i) * samples + j];
            }
        }

        MPI_Wait(&req, MPI_STATUS_IGNORE);

        for (i = 0; i < K; i++)
        {
            for (int j = 0; j < samples; j++)
            {
                auxCentroids[i * samples + j] /= pointsPerClass[i];
            }
        }

        MPI_Allreduce(MPI_IN_PLACE, auxCentroids, K * samples, MPI_FLOAT, MPI_SUM, MPI_COMM_WORLD);

        // 3. Compute the maximum movement of a centroid compared to its previous position
        maxDist = FLT_MIN;
        for (i = 0; i < centroidOffset; i++)
        {
            distCentroids = euclideanDistance(
                &centroids[(startCentroid + i) * samples],
                &auxCentroids[(startCentroid + i) * samples],
                samples
            );

            if (distCentroids > maxDist)
            {
                maxDist = distCentroids;
            }
        }
        MPI_Iallreduce(MPI_IN_PLACE, &maxDist, 1, MPI_FLOAT, MPI_MAX, MPI_COMM_WORLD, &reqs[1]);

        // 4. Re-initialize all the variables for the next iteration
        memcpy(centroids, auxCentroids, (K * samples * sizeof(float)));
        memset(pointsPerClass, 0, K * sizeof(int));
        memset(auxCentroids, 0.0, K * samples * sizeof(float));

        MPI_Waitall(2, reqs, MPI_STATUS_IGNORE);
        sprintf(line, "\n[%d] Cluster changes: %d\tMax. centroid distance: %f", it, changes, maxDist);
        outputMsg = strcat(outputMsg, line);
    }
    while ((changes > minChanges) && (it < maxIterations) && (maxDist > maxThreshold));

    // 5. Gather to the root process all the information that will be written in the output file
    MPI_Gatherv(
        localClassMap, lineOffset,
        MPI_INT, classMap, linesPerProcess,
        displacementPerProcess, MPI_INT, 0, MPI_COMM_WORLD
    );

    /*
     *
     * STOP HERE: DO NOT CHANGE THE CODE BELOW THIS POINT
     *
     */

    //END CLOCK*****************************************
    end = MPI_Wtime();
    localTime = end - start;
    MPI_Reduce(&localTime, &globalTime, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0)
    {
        // Print to stdout all the info about this run
        printf("%s", outputMsg);
        printf("\nComputation: %f seconds", globalTime);
        fflush(stdout);
    }
    //**************************************************
    //START CLOCK***************************************
    MPI_Barrier(MPI_COMM_WORLD);
    start = MPI_Wtime();
    //**************************************************

    if (rank == 0)
    {
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
    free(data);
    free(centroidPos);
    free(centroids);
    free(pointsPerClass);
    free(auxCentroids);

    //END CLOCK*****************************************
    end = MPI_Wtime();
    localTime = end - start;
    MPI_Reduce(&localTime, &globalTime, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0)
    {
        printf("\n\nMemory deallocation: %f seconds\n", globalTime);
        fflush(stdout);
    }
    //***************************************************/
    MPI_Finalize();
    return 0;
}
