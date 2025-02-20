#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda_runtime.h>

#define MY_INFINITY 99999
#define BLK_DIM 256

//struct for the edges of the graph
struct Edge {
    int u;  //start vertex of the edge
    int v;  //end vertex of the edge
    int w;  //weight of the edge (u,v)
};

//Graph - it consists of edges
struct Graph {
    int V;        //total number of vertices in the graph
    int E;        //total number of edges in the graph
    struct Edge *edge;  //array of edges
};

__global__ void sequentialFillDistanceArray(int *d, int tV){
    for(int i=0; i<tV; i++){
        d[i] = MY_INFINITY;
    }
    d[0] = 0;
}

__global__ void sequentialRelaxationStep(struct Edge *edge, int tE, int *d){
    for(int i = 0; i < tE; i++){
        int u = edge[i].u;
        int v = edge[i].v;
        int w = edge[i].w;
        if (d[u] != MY_INFINITY && d[v] > d[u] + w) {
            d[v] = d[u] + w;
        }
    }
}

__global__ void sequentialCheckNegativeCycles(struct Edge *edge, int tE, int *d){
    for(int i = 0; i < tE; i++){
        int u = edge[i].u;
        int v = edge[i].v;
        int w = edge[i].w;
        if (d[u] != MY_INFINITY && d[v] > d[u] + w) {
            printf("Negative cycle found, no solution possible!\n");
        }
    }
}

__global__ void fillDistanceArray(int *d, int tV){
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if (i < tV) {
        d[i] = MY_INFINITY;
    }
    else if(i == 0){
        d[0] = 0;
    }
    
}

__global__ void relaxationStep(struct Edge *edge, int tE, int *d){
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if(i < tE){
        int u = edge[i].u;
        int v = edge[i].v;
        int w = edge[i].w;
        if (d[u] != MY_INFINITY && d[v] > d[u] + w) {
            atomicMin(&d[v], d[u] + w);
        }
    }
}

__global__ void checkNegativeCycles(struct Edge *edge, int tE, int *d){
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if(i < tE){
        int u = edge[i].u;
        int v = edge[i].v;
        int w = edge[i].w;
        if (d[u] != MY_INFINITY && d[v] > d[u] + w) {
            printf("Negative cycle found, no solution possible!\n");
        }
    }
}

void bellmanford(struct Graph *g, int source, int mode){
    int tV = g->V;
    int tE = g->E;
    int *d;
    cudaMalloc(&d, tV * sizeof(int));

    // Allocate memory for edges on device
    // If we create a graph and use memcopy we are not copying the edges themselves
    // so to avoid this issue let's just copy the edges... (lost 2h fixing this)

    struct Edge *edge_dev;
    cudaMalloc(&edge_dev, g->E * sizeof(struct Edge));

    // Copy edges from host to device
    cudaMemcpy(edge_dev, g->edge, g->E * sizeof(struct Edge), cudaMemcpyHostToDevice);

    //fill d
    if(mode == 0){
        fillDistanceArray<<<(tV + BLK_DIM - 1)/BLK_DIM, BLK_DIM>>>(d,tV);
        cudaDeviceSynchronize();
    }
    else{
        sequentialFillDistanceArray<<<1,1>>>(d,tV);
    }

    // Relax edges for tV - 1 iterations
    for (int k = 1; k <= tV - 1; k++) {
        if(mode == 0){
            relaxationStep<<<(tE + BLK_DIM - 1)/BLK_DIM,BLK_DIM>>>(edge_dev, tE, d);
        }
        else{
            sequentialRelaxationStep<<<1,1>>>(edge_dev, tE, d);
        }
    }
    cudaDeviceSynchronize();
    
    //check negative cycles
    if(mode == 0){
        checkNegativeCycles<<<(tE + BLK_DIM - 1)/BLK_DIM,BLK_DIM>>>(edge_dev, tE, d);
        cudaDeviceSynchronize();
    }
    else{
        sequentialCheckNegativeCycles<<<1,1>>>(edge_dev, tE, d);
    }

    // Free device memory
    cudaFree(d);
    cudaFree(edge_dev);
}


int main(int argc, char* argv[]) {

    FILE *file;
    cudaEvent_t start, stop;
    int numVertices = -1;
    int numEdges = -1;
    float elapsed_time;

    if (argc < 2) {
        printf("Usage: %s <filename>\n", argv[0]);
        return 1;
    }

    //opening the file
    file = fopen(argv[1], "r");

    if (file == NULL) {
        printf("Could not open the file.\n");
        return 1;
    }

    int mode = 1;

    if(argc < 3){
        printf("Default mode: sequential\n");
    }
    else if(argc == 3){
        mode = atoi(argv[2]);
    }

    // Read the number of vertices and edges from the file
    fscanf(file, "%d %d", &numVertices, &numEdges);
   
    if (numVertices == -1 || numEdges == -1){
        printf("Wrongly formatted file\n");
        return 0;
    }
    //INIZIALIZATION

    //create graph
    struct Graph *g = (struct Graph *)malloc(sizeof(struct Graph));
    g->V = numVertices;  //total vertices
    g->E = numEdges;  //total edges

    //array of edges for graph
    g->edge = (struct Edge *)malloc(g->E * sizeof(struct Edge));

    // CREATION OF EDGES READING FROM FILE
    for (int i = 0; i < g->E; i++) {
        fscanf(file, "%d %d %d", &g->edge[i].u, &g->edge[i].v, &g->edge[i].w);
    }
    
    fclose(file);

    //start timer
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);

    //bellman ford call
    bellmanford(g, 0, mode);
    
    //end timer
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&elapsed_time, start, stop);   

    elapsed_time /= 1000;
    // Print the elapsed time
    printf("Elapsed time: %f s\n", elapsed_time);
    
    // Clean up resources
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    //WRITE RESULTS TO A FILE

    char *last_word;

    // Find the last occurrence of '\' in the file path
    last_word = strrchr(argv[1], '/');
    int length = strlen(last_word);
    for (int i = 0; i < length; i++) {
        last_word[i] = last_word[i + 1];
    }


    char file_name[256] = "CUDA/resultsCUDA/result_";
    strcat(file_name, last_word);

    // Open the file in append mode
    FILE *output_file = fopen(file_name, "a");
    
    if (output_file == NULL) {
        printf("Error opening file.\n");
        return 0;
    }

    // Write results to the file
    if (mode == 0){
        fprintf(output_file, "Parallel mode,Block size: %d, Elapsed_time: %f\n", BLK_DIM, elapsed_time);
    }
    else{
        fprintf(output_file, "Sequential mode, Elapsed_time: %f\n", elapsed_time);
    }

    // Close the file
    fclose(output_file);

    return 0;
}
