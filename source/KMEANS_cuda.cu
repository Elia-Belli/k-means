/*
 * k-Means clustering algorithm
 *
 * CUDA version
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
#include <cuda.h>


#define MAXLINE 2000
#define MAXCAD 200

//Macros
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

void getDeviceProperties(int device, int* SMcount, int* maxThreadsPerBlock, size_t* maxSharedMem);
int getBlockSize(int threads, size_t sharedPerThread, int regsPerThread);

/*
 * Macros to show errors when calling a CUDA library function,
 * or after launching a kernel
 */
#define CHECK_CUDA_CALL( a )	{ \
	cudaError_t ok = a; \
	if ( ok != cudaSuccess ) \
		fprintf(stderr, "-- Error CUDA call in line %d: %s\n", __LINE__, cudaGetErrorString( ok ) ); \
	}
#define CHECK_CUDA_LAST()	{ \
	cudaError_t ok = cudaGetLastError(); \
	if ( ok != cudaSuccess ) \
		fprintf(stderr, "-- Error CUDA last in line %d: %s\n", __LINE__, cudaGetErrorString( ok ) ); \
	}

__device__
static float atomicMax(float* address, float val)
{
    int* address_as_i = (int*) address;
    int old = *address_as_i, assumed;
    do {
        assumed = old;
        old = ::atomicCAS(address_as_i, assumed,
            __float_as_int(::fmaxf(val, __int_as_float(assumed))));
    } while (assumed != old);
    return __int_as_float(old);
}

__device__
float euclideanDistance(float *point, float *center, int samples)
{
	float dist = 0.0;
	for(int i = 0; i < samples; i++) 
	{
		dist += (point[i]-center[i])*(point[i]-center[i]);
	}

	dist = sqrt(dist);
	return dist;
}


__global__ void kmeansMapClass(float *data, float *centroids, int *classMap, int *pointsPerClass,
            int* changes, int lines, int samples, int K)
{
    int globID = blockIdx.x * blockDim.x + threadIdx.x;
    int locID = threadIdx.x;
    int i;

    extern __shared__ int shared[];  
    int* localPointsPerClass = (int*) &shared[0];
    int* localChanges = (int*) &shared[K];
    float* localCentroids = (float*) &shared[K+1]; 

    float minDist = FLT_MAX, dist;
    int cluster = 1;

    // Init shared pointsPerClass
    for(i = locID; i < K; i += blockDim.x)
    {
        localPointsPerClass[i] = 0;
    }

    // Copy centroids in SharedMem to reduce global memory access
    for(i = locID; i < K*samples; i += blockDim.x)
    {
        localCentroids[i] = centroids[i];
    }

    if(locID == 0) localChanges[0] = 0;

    __syncthreads();

    if(globID < lines)
    {
        for(i = 0; i < K; i++)
        {
            dist = euclideanDistance(&data[globID * samples], &localCentroids[i * samples], samples);

            if(dist < minDist)
            {
                minDist = dist;
                cluster = i+1;
            }
        }

        if(classMap[globID] != cluster)
        {
            atomicAdd(localChanges, 1);
            classMap[globID] = cluster;
        }

        atomicAdd(&localPointsPerClass[cluster-1], 1);

    }

    __syncthreads();

    atomicAdd(changes, *localChanges);

    // Sum localPointPerClass in global pointsPerClass
    for(i = locID; i < K; i += blockDim.x)
    {
        atomicAdd(&pointsPerClass[i], localPointsPerClass[i]);
    }
}

__global__ void kmeansMapClassTiling(float *data, float *centroids, int *classMap, int *pointsPerClass,
            int* changes, int lines, int samples, int K)
{
    int globID = blockIdx.x * blockDim.x + threadIdx.x;
    int locID = threadIdx.x;

    extern __shared__ int shared[];
    int *localPointsPerClass = (int*) &shared[0];
    int *localChanges = (int*) &shared[K];
    float *centroid = (float*) &shared[K+1];

    float minDist = FLT_MAX, dist;
    int i, j, cluster = 1;

    // Init shared pointsPerClass
    for(i = locID; i < K; i += blockDim.x)
    {
        localPointsPerClass[i] = 0;
    }

    if(locID == 0) 
    {
        *localChanges = 0;
    }

    
    for(i = 0; i < K; i++)
    {   
        
        for(j = locID; j < samples; j+=blockDim.x)
        {
            centroid[j] = centroids[i*samples + j];
        }
        __syncthreads();

        if(globID < lines)
        {
            dist = euclideanDistance(&data[globID * samples], &centroids[i * samples], samples);

            if(dist < minDist)
            {
                minDist = dist;
                cluster = i+1;
            }
        }
        __syncthreads();

    }

    if(globID < lines)
    {
        if(classMap[globID] != cluster)
        {
            atomicAdd(localChanges, 1);
            classMap[globID] = cluster;
        }

        atomicAdd(&localPointsPerClass[cluster-1], 1);

    }

    __syncthreads();

    if(locID == 0)
    {
        atomicAdd(changes, *localChanges);
    }

    for(i = locID; i < K; i+=blockDim.x)
    {
        atomicAdd(&pointsPerClass[i], localPointsPerClass[i]);
    }
}


// 2. 
__global__ void kmeansCentroidsSum(float *data, float *auxCentroids, int *pointPerClass, int *classMap,
                            int lines, int samples, int K)
{   
    int globID = blockIdx.x * blockDim.x + threadIdx.x;
    int gridSize = gridDim.x * blockDim.x;
    int i, cluster;

    if(globID < lines)
    {
        cluster = classMap[globID] - 1;
        for(i = 0; i < samples; i++)
        {
            atomicAdd(&auxCentroids[cluster * samples + i], data[globID * samples + i]);
        }
    }
}

// 3. Before we summed directly data[]/pointsPerClass[] in auxCentroids[]
//      but doing so requires (lines*samples) divisions
//    Since K << lines, doing the division after the sum reduces the number of div
__global__ void kmeansCentroidsDiv(float* auxCentroids, int* pointsPerClass, int samples, int K)
{
    int globID = blockIdx.x * blockDim.x + threadIdx.x;
    int gridSize = gridDim.x * blockDim.x;
    int i;

    for(i = globID; i < K*samples; i += gridSize)
    {
        auxCentroids[i] /= pointsPerClass[i/samples];
    } 
}

__global__ void kmeansMaxDist(float *auxCentroids, float* centroids, int* pointPerClass, 
                                float* maxDist, int samples, int K)
{   
    int globID = blockIdx.x * blockDim.x + threadIdx.x;
    int gridSize = gridDim.x * blockDim.x;

    __shared__ float localMaxDist;
    
    int i;
    float dist;

    if(globID == 0) 
        localMaxDist = 0;

    __syncthreads();

    for(i = globID; i < K; i += gridSize)
    {
        dist = euclideanDistance(&auxCentroids[i * samples], &centroids[i * samples], samples);
        atomicMax(&localMaxDist, dist);
    }

    __syncthreads();
    if(globID == 0) 
        atomicMax(maxDist, localMaxDist);
    
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
			fprintf(stderr,"\tFile %s has too many columns.\n", filename);
			fprintf(stderr,"\tThe maximum number of columns has been exceeded. MAXLINE: %d.\n", MAXLINE);
			break;
		case -2:
			fprintf(stderr,"Error reading file: %s.\n", filename);
			break;
		case -3:
			fprintf(stderr,"Error writing file: %s.\n", filename);
			break;
	}
	fflush(stderr);	
}

/* 
Function readInput: It reads the file to determine the number of rows and columns.
*/
int readInput(char* filename, int *lines, int *samples)
{
    FILE *fp;
    char line[MAXLINE] = "";
    char *ptr;
    const char *delim = "\t";
    int contlines, contsamples = 0;
    
    contlines = 0;

    if ((fp=fopen(filename,"r"))!=NULL)
    {
        while(fgets(line, MAXLINE, fp)!= NULL) 
		{
			if (strchr(line, '\n') == NULL)
			{
				return -1;
			}
            contlines++;       
            ptr = strtok(line, delim);
            contsamples = 0;
            while(ptr != NULL)
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
    FILE *fp;
    char line[MAXLINE] = "";
    char *ptr;
    const char *delim = "\t";
    int i = 0;
    
    if ((fp=fopen(filename,"rt"))!=NULL)
    {
        while(fgets(line, MAXLINE, fp)!= NULL)
        {         
            ptr = strtok(line, delim);
            while(ptr != NULL)
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
int writeResult(int *classMap, int lines, const char* filename)
{	
    FILE *fp;
    
    if ((fp=fopen(filename,"wt"))!=NULL)
    {
        for(int i=0; i<lines; i++)
        {
        	fprintf(fp,"%d\n",classMap[i]);
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
void initCentroids(const float *data, float* centroids, int* centroidPos, int samples, int K)
{
	int i;
	int idx;
	for(i=0; i<K; i++)
	{
		idx = centroidPos[i];
		memcpy(&centroids[i*samples], &data[idx*samples], (samples*sizeof(float)));
	}
}

/*
Function euclideanDistance: Euclidean distance
This function could be modified
*/
float euclideanDistanceCPU(float *point, float *center, int samples)
{
	float dist=0.0;
	for(int i=0; i<samples; i++) 
	{
		dist+= (point[i]-center[i])*(point[i]-center[i]);
	}
	dist = sqrt(dist);
	return(dist);
}


/*
Function zeroFloatMatriz: Set matrix elements to 0
This function could be modified
*/
void zeroFloatMatriz(float *matrix, int rows, int columns)
{
	int i,j;
	for (i=0; i<rows; i++)
		for (j=0; j<columns; j++)
			matrix[i*columns+j] = 0.0;	
}

/*
Function zeroIntArray: Set array elements to 0
This function could be modified
*/
void zeroIntArray(int *array, int size)
{
	int i;
	for (i=0; i<size; i++)
		array[i] = 0;	
}



int main(int argc, char* argv[])
{

	//START CLOCK***************************************
	double start, end;
	start = clock();
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
	if(argc !=  7)
	{
		fprintf(stderr,"EXECUTION ERROR K-MEANS: Parameters are not correct.\n");
		fprintf(stderr,"./KMEANS [Input Filename] [Number of clusters] [Number of iterations] [Number of changes] [Threshold] [Output data file]\n");
		fflush(stderr);
		exit(-1);
	}

	// Reading the input data
	// lines = number of points; samples = number of dimensions per point
	int lines = 0, samples= 0;  
	
	int error = readInput(argv[1], &lines, &samples);
	if(error != 0)
	{
		showFileError(error,argv[1]);
		exit(error);
	}
	
	float *data = (float*)calloc(lines*samples,sizeof(float));
	if (data == NULL)
	{
		fprintf(stderr,"Memory allocation error.\n");
		exit(-4);
	}
	error = readInput2(argv[1], data);
	if(error != 0)
	{
		showFileError(error,argv[1]);
		exit(error);
	}

	// Parameters
	int K=atoi(argv[2]); 
	int maxIterations=atoi(argv[3]);
	int minChanges= (int)(lines*atof(argv[4])/100.0);
	float maxThreshold=atof(argv[5]);

	int *centroidPos = (int*)calloc(K,sizeof(int));
	float *centroids = (float*)calloc(K*samples,sizeof(float));
	int *classMap = (int*)calloc(lines,sizeof(int));

    if (centroidPos == NULL || centroids == NULL || classMap == NULL)
	{
		fprintf(stderr,"Memory allocation error.\n");
		exit(-4);
	}

	// Initial centrodis
	srand(0);
	int i;
	for(i=0; i<K; i++) 
		centroidPos[i]=rand()%lines;
	
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
		end = clock();
		printf("\nMemory allocation: %f seconds\n", (double)(end - start) / CLOCKS_PER_SEC);
		fflush(stdout);
    #endif

	CHECK_CUDA_CALL( cudaSetDevice(0) );
	CHECK_CUDA_CALL( cudaDeviceSynchronize() );
	//**************************************************
	//START CLOCK***************************************
	start = clock();
	//**************************************************
	char *outputMsg = (char *)calloc(10000,sizeof(char));
	char line[100];

	// int j;
	// int classe;
	// float dist, minDist;
	int it=1;
	int changes = 0;
	float maxDist;

	//pointPerClass: number of points classified in each class
	//auxCentroids: mean of the points in each class
	int *pointsPerClass = (int *)malloc(K*sizeof(int));
	float *auxCentroids = (float*)malloc(K*samples*sizeof(float));
	float *distCentroids = (float*)malloc(K*sizeof(float)); 
	if (pointsPerClass == NULL || auxCentroids == NULL || distCentroids == NULL)
	{
		fprintf(stderr,"Memory allocation error.\n");
		exit(-4);
	}

/*
 *
 * START HERE: DO NOT CHANGE THE CODE ABOVE THIS POINT
 *
 */
    int SMcount, maxThreadsPerBlock;
    size_t maxSharedMem, sharedMapClassBase, sharedMapClassTiling, sharedMapClass;
    getDeviceProperties(0, &SMcount, &maxThreadsPerBlock, &maxSharedMem);

    sharedMapClassTiling = (K+1+samples) * sizeof(int) ;
    sharedMapClassBase = (K+1) * sizeof(int) + (K*samples) * sizeof(float);

    float *d_data, *d_centroids, *d_auxCentroids, *d_maxDist;
    int *d_classMap, *d_changes, *d_pointPerClass;
    int anotherIteration = 1;

    int gridSize, blockSize; 
    blockSize = getBlockSize(lines, sharedMapClass, 32);
    gridSize = ceil(lines/blockSize);

    #ifdef DEBUG
    printf("\nBlockSize: %d\n\n", blockSize);
    #endif

    // Allocation of GPU data structures
    CHECK_CUDA_CALL(cudaMalloc((void**) &d_data, lines*samples*sizeof(float)));  
    CHECK_CUDA_CALL(cudaMalloc((void**) &d_centroids, K*samples*sizeof(float)));     
    CHECK_CUDA_CALL(cudaMalloc((void**) &d_auxCentroids, K*samples*sizeof(float)));  
    CHECK_CUDA_CALL(cudaMalloc((void**) &d_classMap, lines*sizeof(int)));    
    CHECK_CUDA_CALL(cudaMalloc((void**) &d_pointPerClass, K*sizeof(int)));    
    CHECK_CUDA_CALL(cudaMalloc((void**) &d_maxDist, sizeof(float))); 
    CHECK_CUDA_CALL(cudaMalloc((void**) &d_changes, sizeof(int)));   

    // Send data and initial centroids to GPU
    CHECK_CUDA_CALL(cudaMemcpy(d_data, data, lines*samples*sizeof(float), cudaMemcpyHostToDevice));
    CHECK_CUDA_CALL(cudaMemcpy(d_centroids, centroids, K*samples*sizeof(float), cudaMemcpyHostToDevice));
    // Initialize ClassMap on GPU
    CHECK_CUDA_CALL(cudaMemset(d_classMap, 0, lines*sizeof(int)));
    
    // Kernel Arguments
    void* argsMapClass[] = {&d_data, &d_centroids, &d_classMap, &d_pointPerClass, &d_changes, &lines, &samples, &K};
    void* argsCentroidsSum[] = {&d_data, &d_auxCentroids, &d_pointPerClass, &d_classMap, &lines, &samples, &K};
    void* argsCentroidsDiv[] = {&d_auxCentroids, &d_pointPerClass, &samples, &K};
    void* argsMaxDist[] = {&d_auxCentroids, &d_centroids, &d_pointPerClass, &d_maxDist, &samples, &K};

	do{
        // Initialize MaxDist & Changes on GPU
        CHECK_CUDA_CALL(cudaMemset(d_changes, 0, sizeof(int)));
        CHECK_CUDA_CALL(cudaMemset(d_maxDist, FLT_MIN, sizeof(float)));
        CHECK_CUDA_CALL(cudaMemset(d_auxCentroids, 0.0, K*samples*sizeof(float)));
        CHECK_CUDA_CALL(cudaMemset(d_pointPerClass, 0, K*sizeof(int)));

        // Kernerls
        if(sharedMapClassBase < maxSharedMem)
        {
            CHECK_CUDA_CALL(cudaLaunchKernel((void*) kmeansMapClass, gridSize, blockSize, argsMapClass, sharedMapClassBase, NULL));
        }else
        {
            CHECK_CUDA_CALL(cudaLaunchKernel((void*) kmeansMapClassTiling, gridSize, blockSize, argsMapClass, sharedMapClassTiling, NULL));
        }
        CHECK_CUDA_CALL(cudaDeviceSynchronize());

        CHECK_CUDA_CALL(cudaLaunchKernel((void*) kmeansCentroidsSum, gridSize, blockSize, argsCentroidsSum, 0, NULL));
        CHECK_CUDA_CALL(cudaDeviceSynchronize());

        CHECK_CUDA_CALL(cudaLaunchKernel((void*) kmeansCentroidsDiv, gridSize, blockSize, argsCentroidsDiv, 0, NULL));
        CHECK_CUDA_CALL(cudaDeviceSynchronize());

        CHECK_CUDA_CALL(cudaLaunchKernel((void*) kmeansMaxDist, gridSize, blockSize, argsMaxDist, sizeof(float), NULL));
        CHECK_CUDA_CALL(cudaDeviceSynchronize());

        // Get MaxDist & Changes back to CPU
        CHECK_CUDA_CALL(cudaMemcpy(&maxDist, d_maxDist, sizeof(float), cudaMemcpyDeviceToHost));
        CHECK_CUDA_CALL(cudaMemcpy(&changes, d_changes, sizeof(int), cudaMemcpyDeviceToHost));

        // Print iteration info
        #ifdef DEBUG
        sprintf(line, "\n[%d] Cluster changes: %d\tMax. centroid distance: %f", it, changes, maxDist);
        outputMsg = strcat(outputMsg, line);
        #endif

        // Check Termination Conditions
        anotherIteration = (changes > minChanges) && (it < maxIterations) && (maxDist > maxThreshold);

        if(anotherIteration){
            // Update Centroids for the next iteration
            CHECK_CUDA_CALL(cudaMemcpy(d_centroids, d_auxCentroids, K*samples*sizeof(float), cudaMemcpyDeviceToDevice));    
            it++;
        }
        
    } while(anotherIteration);

    // Copy final ClassMap on CPU
    CHECK_CUDA_CALL(cudaMemcpy(classMap, d_classMap, lines*sizeof(int), cudaMemcpyDeviceToHost));

    // Free GPU memory
    CHECK_CUDA_CALL(cudaFree(d_pointPerClass));
    CHECK_CUDA_CALL(cudaFree(d_classMap));
    CHECK_CUDA_CALL(cudaFree(d_centroids)); 
    CHECK_CUDA_CALL(cudaFree(d_auxCentroids));
    CHECK_CUDA_CALL(cudaFree(d_data));
    CHECK_CUDA_CALL(cudaFree(d_maxDist));
    CHECK_CUDA_CALL(cudaFree(d_changes));

/*
 *
 * STOP HERE: DO NOT CHANGE THE CODE BELOW THIS POINT
 *
 */
	// Output and termination conditions

	CHECK_CUDA_CALL( cudaDeviceSynchronize() );

	//END CLOCK*****************************************
	end = clock();
    #ifdef DEBUG
		printf("%s",outputMsg);
		printf("\nComputation: %f seconds", (double)(end - start) / CLOCKS_PER_SEC);
		if (changes <= minChanges) {
			printf("\n\nTermination condition:\nMinimum number of changes reached: %d [%d]", changes, minChanges);
		}
		else if (it >= maxIterations) {
			printf("\n\nTermination condition:\nMaximum number of iterations reached: %d [%d]", it, maxIterations);
		}
		else {
			printf("\n\nTermination condition:\nCentroid update precision reached: %g [%g]", maxDist, maxThreshold);
		}
    #else
        printf("cuda,%f", (double)(end - start) / CLOCKS_PER_SEC);
	#endif
	fflush(stdout);
	//**************************************************
	//START CLOCK***************************************
	start = clock();
	//**************************************************

	// Writing the classification of each point to the output file.
	error = writeResult(classMap, lines, argv[6]);
	if(error != 0)
	{
		showFileError(error, argv[6]);
		exit(error);
	}

	//Free memory
	free(data);
	free(classMap);
	free(centroidPos);
	free(centroids);
	free(distCentroids);
	free(pointsPerClass);
	free(auxCentroids);

	//END CLOCK*****************************************
    #ifdef DEBUG
	end = clock();
	printf("\n\nMemory deallocation: %f seconds\n",(double)(end - start) / CLOCKS_PER_SEC);
	fflush(stdout);
    #endif
	//***************************************************/
	return 0;
}


/*
    Gets properties of cuda device
    in: int device (number of device)
    out: int* SMcount, int* maxSharedMem
*/
void getDeviceProperties(int device, int* SMcount, int* threadsPerBlock, size_t* maxSharedMem)
{
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, device);

    *SMcount = prop.multiProcessorCount;
    *threadsPerBlock = prop.maxThreadsPerBlock;
    *maxSharedMem = prop.sharedMemPerBlock;

    #ifdef DEBUG
    printf("  Memory Clock Rate (MHz): %d\n", prop.memoryClockRate/1024);
    printf("  Memory Bus Width (bits): %d\n", prop.memoryBusWidth);

    printf("  Peak Memory Bandwidth (GB/s): %.1f\n",
        2.0*prop.memoryClockRate*(prop.memoryBusWidth/8)/1.0e6);
    printf("  Total global memory (Gbytes) %.1f\n",(float)(prop.totalGlobalMem)/1024.0/1024.0/1024.0);
    printf("  Shared memory per block (Bytes) %.1f\n",(float)(prop.sharedMemPerBlock));
    printf("  Shared memory per SM (Bytes) %.1f\n",(float)(prop.sharedMemPerMultiprocessor));
    
    printf("  SM count : %d\n", prop.multiProcessorCount);
    printf("  Warp-size: %d\n", prop.warpSize);
    printf("  max-grid-size: (%d, %d, %d)\n", prop.maxGridSize[0],prop.maxGridSize[1],prop.maxGridSize[2]);
    printf("  max-threads-per-block: %d\n", prop.maxThreadsPerBlock);
    printf("  max-threads-per-multiprocessor: %d\n", prop.maxThreadsPerMultiProcessor);
    printf("  register-per-block: %d\n", prop.regsPerBlock);
    #endif
    
}

int getBlockSize(int threads, size_t sharedPerThread, int regsPerThread)
{
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);

    int warpSize = prop.warpSize;
    int regsPerBlock = prop.regsPerBlock;
    int sharedMemory = prop.sharedMemPerBlock;

    // For cc >= 3.0 we have at least 4 warpSchedulers per SM

    /* Registers per Thread for each kernel
    - kmeansMapClass : 32
    - kmeansMapClassOptimized : 30
    - kmeansCentroidsSum : 18
    - kmeansCentroidsDiv : 20
    - kmeansMaxDist : 29
    */

    int criterias[3];
    criterias[0] = 4 * warpSize;
    criterias[1] = regsPerBlock/32;
    criterias[2] = prop.maxThreadsPerMultiProcessor;

    int blockSize = min(min(criterias[0],criterias[1]), criterias[2]);

    blockSize = warpSize * ceil(blockSize/warpSize);

    return blockSize;
}