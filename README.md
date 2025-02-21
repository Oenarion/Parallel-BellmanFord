# Parallel-BellmanFord
An implementation of the BellmanFord algorithm in CUDA and OpenMP.

# Graph generation:
The first thing that is needed to run the BellmanFord algorithm are the graphs! This operation is handled by the **`graph_creator.py`**, it's a pretty straightforward creation it takes:
- The number of vertices
- The number of total edges
- The number of the file to be created

Then it just randomly creates non overlapping edges between vertices from 0 to n-1 until the number of total edges is satisfied. <br>
Finally, the file containing all the infos about the graph is created as `"example" + {argv[3]} + ".txt"`, the final file contains the first two lines with the number of vertices and edges. All the other lines express the structure of our graph in the form of an adjacency list, so the format is **`u, v, w`** where **`u`** is the starting vertex, **`v`** is the ending vertex and **`w`** is the weight.

# OpenMP
To compile the openMP file simply run the command: <br>
```
gcc -o bellman_openmp bellman_openmp.c -fopenmp
```

<br>
To execute it run the command: <br>

```
./bellman_openmp <file_input> [num_threads]
```

The results of the computation, i.e. threads used and time elapsed, will be saved in the corresponding **`openMP/resultsOpenMP/results_example{num_example}.txt`**  file.

# CUDA
To compile the CUDA file simply run the command: <br>

```
nvcc -o bellman_cuda bellman_cuda.cu
```

<br>
To execute it run the command: <br> 

```
./bellman_cuda <file_input> [mode]
```

<br> 
where mode = 0 indicates parallel mode, else if a different number or no number at all is passed, sequential mode will be used.

As for OpenMP, the results of the computation, i.e. BLOCK_SIZE used and time elapsed, will be saved in the corresponding **`CUDA/resultsCUDA/results_example{num_example}.txt`** file.

# Sbatch file
The project can be run on a slurm cluster which accepts sbatch files, when runnning the sbatch file as 
```
sbatch project.sbatch
```
this happens:
- The directories with past results will be deleted and recreated
- The OpenMP file will be run for all the graphs examples found in the corresponding directory, for [1, 2, 4, 8, 16, 32, 64] threads.
- The CUDA file will be run for all the graphs examples found in the corresponding directory in both sequential and parallel mode, note that BLOCK_SIZE is set to 256.

# Speedup
Finally to evaluate the results of both OpenMP and CUDA the **`speedup.py`** program was created, its function is just to show the speedup obtained in both processes through the use of the matplotlib library.

# Not satisfied?
Want more informations about the project? <br>
Just read the project.pdf, it should contain all the answers to questions which were not answered before!
