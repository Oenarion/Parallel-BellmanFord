#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>

#define INFINITY 99999

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

void bellmanford(struct Graph *g, int source);

int main(int argc, char* argv[]) {

    FILE *file;
    int numVertices = -1;
    int numEdges = -1;
    
    char line[256]; 

    if (argc < 2) {
        printf("Usage: %s <filename>\n", argv[0]);
        return 1;
    }

    printf("file: %s", argv[1]);
    file = fopen(argv[1], "r");

    if (file == NULL) {
        printf("Could not open the file.\n");
        return 1;
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

    int num_threads = 1;

    // HANDLE NUM OF THREADS
    if ( argc == 3 ){
        num_threads = atoi( argv[2] );
    }

    // Set the number of threads for OpenMP
    omp_set_num_threads(num_threads);

    printf("NUMBER OF THREADS IS: %d \n\n", num_threads);
    //start the timer
    double tstart, tstop;
    tstart = omp_get_wtime();

    bellmanford(g, 0);  //0 is the source vertex for simplicity

    tstop = omp_get_wtime();
    double elapsed_time = tstop - tstart;
    printf("TIME ELAPSED WITH %d THREADS IS: %f",num_threads, elapsed_time);

    // WRITE RESULTS TO A FILE
    char *last_word;

    // Find the last occurrence of '/' in the file path
    
    last_word = strrchr(argv[1], '/');
    int length = strlen(last_word);
    for (int i = 0; i < length; i++) {
        last_word[i] = last_word[i + 1];
    }

    char file_name[256] = "openMP/resultsOpenMP/result_";
    strcat(file_name, last_word);
    
    // Open the file in append mode
    FILE *output_file = fopen(file_name, "a");
    if (output_file == NULL) {
        printf("Error opening file.\n");
        return 0;
    }

    // Write results to the file
    fprintf(output_file, "Threads: %d, Elapsed_time: %f\n", num_threads, elapsed_time);

    // Close the file
    fclose(output_file);
    return 0;
}

void bellmanford(struct Graph *g, int source) {
    //variables
    int i, j, u, v, w;

    //total vertex in the graph g
    int tV = g->V;

    //total edge in the graph g
    int tE = g->E;

    //distance array, size equal to the number of vertices of the graph g
    int *d = (int *)malloc(tV * sizeof(int)); 
    
    //checks for negatives in the end
    int check = 0;

    //first parallelization
    #pragma omp parallel for
    //step 1: fill the distance array and predecessor array
    for (i = 0; i < tV; i++) {
        d[i] = INFINITY;
    }

    //mark the source vertex
    d[source] = 0;

    //step 2: relax edges |V| - 1 times
    for (i = 1; i <= tV - 1; i++) {
        //second parallelization
        #pragma omp parallel for private (u,v,w) shared(d)
        for (j = 0; j < tE; j++) {
            //get the edge data
            u = g->edge[j].u;
            v = g->edge[j].v;
            w = g->edge[j].w;
            if (d[u] != INFINITY && d[v] > d[u] + w) {
                int new_dist = d[u] + w;
                //to ensure correctness in the d update a critical section must be used
                #pragma omp critical
                {
                if (new_dist < d[v]){
                    d[v] = new_dist;
		}
                }
            }
        }
    }

    //step 3: detect negative cycle
    //if check value changes then we have a negative cycle in the graph and we cannot find the shortest distances
    //third parallelization
    #pragma omp parallel for reduction(|:check)
    for (int i = 0; i < tE; i++) {
        int u = g->edge[i].u;
        int v = g->edge[i].v;
        int w = g->edge[i].w;
        if (d[u] != INFINITY && d[v] > d[u] + w) {
            // Set the flag if a negative weight cycle is found
            check = 1;
        }
    }

    if (check) {
        printf("Negative weight cycle detected!\n");
    } else {
        printf("No negative weight cycle found\n");
    }

    // Free allocated memory
    free(d);
}

