/*
 * k-Means clustering algorithm
 *
 * OpenMP version
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
#include <omp.h>
#include <assert.h>

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
    //START CLOCK***************************************
    double start, end;
    start = omp_get_wtime();
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
        exit(-1);
    }

    // Reading the input data
    // lines = number of points; samples = number of dimensions per point
    int tmpLines = 0, tmpSamples = 0;

    int error = readInput(argv[1], &tmpLines, &tmpSamples);
    if (error != 0)
    {
        showFileError(error, argv[1]);
        exit(error);
    }

    const int lines = tmpLines, samples = tmpSamples;

    float* data = (float*)calloc(lines * samples, sizeof(float));
    if (data == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        exit(-4);
    }
    error = readInput2(argv[1], data);
    if (error != 0)
    {
        showFileError(error, argv[1]);
        exit(error);
    }

    // Parameters
    const int K = atoi(argv[2]);
    int maxIterations = atoi(argv[3]);
    int minChanges = (int)(lines * atof(argv[4]) / 100.0);
    float maxThreshold = atof(argv[5]);


    int* centroidPos = (int*)calloc(K, sizeof(int));
    float* centroids = (float*)calloc(K * samples, sizeof(float));
    int* classMap = (int*)calloc(lines, sizeof(int));

    if (centroidPos == NULL || centroids == NULL || classMap == NULL)
    {
        fprintf(stderr, "Memory allocation error.\n");
        exit(-4);
    }

    // Initial centrodis
    srand(0);
    for (int i = 0; i < K; i++)
        centroidPos[i] = rand() % lines;

    // Loading the array of initial centroids with the data from the array data
    // The centroids are points stored in the data array.
    initCentroids(data, centroids, centroidPos, samples, K);

    #ifdef DEBUG
    printf("\n\tData file: %s \n\tPoints: %d\n\tDimensions: %d\n", argv[1], lines, samples);
    printf("\tNumber of clusters: %d\n", K);
    printf("\tMaximum number of iterations: %d\n", maxIterations);
    printf("\tMinimum number of changes: %d [%g%% of %d points]\n", minChanges, atof(argv[4]), lines);
    printf("\tMaximum centroid precision: %f\n", maxThreshold);
    #endif

    //END CLOCK*****************************************
    #ifdef DEBUG
    end = omp_get_wtime();
    printf("\nMemory allocation: %f seconds\n", end - start);
    fflush(stdout);
    #endif
    //**************************************************
    //START CLOCK***************************************
    start = omp_get_wtime();
    //**************************************************
    char* outputMsg = (char*)calloc(10000, sizeof(char));
    char line[100];

    const char* RAW_OMP_NUM_THREADS = getenv("OMP_NUM_THREADS");
    const int OMP_NUM_THREADS = (RAW_OMP_NUM_THREADS != NULL) ? (atoi(RAW_OMP_NUM_THREADS)) : omp_get_max_threads();

    int changes = 0;
    int it = 1;
    int i, j, cluster;
    int anotherIteration = 0;
    int auxCentroidsSize = K * samples;
    float_t dist, minDist = FLT_MAX, maxDist = FLT_MIN;

    // pointPerClass: number of points classified in each class
    // auxCentroids: mean of the points in each class
    int* pointsPerClass = calloc(K, sizeof(int));
    float* auxCentroids = calloc(auxCentroidsSize, sizeof(float));
    assert(pointsPerClass != NULL && auxCentroids != NULL);

    memset(auxCentroids, 0.0, auxCentroidsSize * sizeof(float));
    memset(pointsPerClass, 0, K * sizeof(int));

    # pragma omp parallel num_threads(OMP_NUM_THREADS) private(i, j, cluster, dist, minDist)
    {
        do
        {
            // 1. Assign each point to a class and count the elements in each class
            # pragma omp for nowait reduction(+:changes, pointsPerClass[:K])
            for (i = 0; i < lines; i++)
            {
                cluster = 1, minDist = FLT_MAX;
                for (j = 0; j < K; j++)
                {
                    dist = euclideanDistance(&data[i * samples], &centroids[j * samples], samples);

                    if (dist < minDist)
                    {
                        minDist = dist;
                        cluster = j + 1;
                    }
                }

                if (classMap[i] != cluster)
                {
                    classMap[i] = cluster;
                    changes++;
                }
                pointsPerClass[cluster - 1]++;
            }

            // 2. Compute the partial sum of all the coordinates of point within the same cluster
            # pragma omp for reduction(+:auxCentroids[:auxCentroidsSize])
            for (i = 0; i < lines; i++)
            {
                cluster = classMap[i] - 1;
                for (j = 0; j < samples; j++)
                {
                    auxCentroids[cluster * samples + j] += data[i * samples + j];
                }
            }

            # pragma omp for nowait
            for (i = 0; i < K; i++)
            {
                for (j = 0; j < samples; j++)
                {
                    auxCentroids[i * samples + j] /= pointsPerClass[i];
                }
            }

            // 3. Get the maximum movement of a centroid compared to its previous position
            # pragma omp for reduction(max:maxDist)
            for (i = 0; i < K; i++)
            {
                dist = euclideanDistance(&centroids[i * samples], &auxCentroids[i * samples], samples);

                if (dist > maxDist)
                {
                    maxDist = dist;
                }
                pointsPerClass[i] = 0;
            }

            // 4. Check termination conditions and clean memory for the next iteration
            # pragma omp single
            {
                #ifdef DEBUG
                sprintf(line, "\n[%d] Cluster changes: %d\tMax. centroid distance: %f", it, changes, maxDist);
                outputMsg = strcat(outputMsg, line);
                #endif

                anotherIteration = (changes > minChanges) && (it < maxIterations) && (maxDist > maxThreshold);

                if (anotherIteration)
                {
                    it++;
                    maxDist = FLT_MIN;
                    changes = 0;
                    memcpy(centroids, auxCentroids, (auxCentroidsSize * sizeof(float)));
                    memset(auxCentroids, 0.0, auxCentroidsSize * sizeof(float));
                }
            }
        }
        while (anotherIteration);
    }
    // Output and termination conditions

    //END CLOCK*****************************************
    end = omp_get_wtime();
    #ifdef DEBUG
    printf("%s", outputMsg);
    printf("\nComputation: %f seconds", end - start);
    #else
    printf("omp,%f", end - start);
    #endif
    fflush(stdout);
    //**************************************************
    //START CLOCK***************************************
    start = omp_get_wtime();
    //**************************************************

    #ifdef DEBUG
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
    #endif

    // Writing the classification of each point to the output file.
    error = writeResult(classMap, lines, argv[6]);
    if (error != 0)
    {
        showFileError(error, argv[6]);
        exit(error);
    }

    //Free memory
    free(data);
    free(classMap);
    free(centroidPos);
    free(centroids);
    free(pointsPerClass);
    free(auxCentroids);
    free(outputMsg);

    //END CLOCK*****************************************
    #ifdef DEBUG
    end = omp_get_wtime();
    printf("\n\nMemory deallocation: %f seconds\n", end - start);
    fflush(stdout);
    #endif
    //***************************************************/
    return 0;
}
