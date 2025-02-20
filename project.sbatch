#!/bin/bash
#SBATCH --job-name=bellmanford_parallel
#SBATCH --output=output_%j.txt
#SBATCH --error=error_%j.txt
#SBATCH --ntasks-per-node=4
#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --gres=gpu:1

# Set the number of threads
num_threads=(1 2 4 8 16 32 64)

# Load necessary modules if required
# module load <module_name>

gcc -fopenmp "$PWD/openMP/bellmanFordOpenMP.c" -o "$PWD/openMP/bellmanFordOpenMP.exe"

chmod +x "$PWD/openMP/bellmanFordOpenMP.exe"

#recreate the directory to delete past runs
rm -rf "$PWD/openMP/resultsOpenMP/"
rm -rf "$PWD/CUDA/resultsCUDA/"

mkdir "$PWD/openMP/resultsOpenMP/"
mkdir "$PWD/CUDA/resultsCUDA/" 

# Define input directory relative to the current working directory
input_directory="$PWD/graph_examples"

# Specify the path to your pre-compiled executable file relative to the current working directory
executable_file="$PWD/openMP/bellmanFordOpenMP.exe"

echo "STARTING FOR LOOP OPENMP"
# Iterate over files in the input directory
for file in "$input_directory"/*; do
    if [ -f "$file" ]; then

        # Iterate over the number of threads
        for i in "${num_threads[@]}"; do
            # Execute your pre-compiled executable file with the specified number of threads
            echo "Executing $executable_file with $i threads and input file $file"
            "$executable_file" "$file" "$i"
	done
    fi
done

echo "END OPENMP"

nvcc "$PWD/CUDA/bellmanFordCUDA.cu" -o "$PWD/CUDA/bellmanFordCUDA.exe"

# Specify the path to your pre-compiled executable file relative to the current working directory
executable_file="$PWD/CUDA/bellmanFordCUDA.exe"

echo "STARTING FOR LOOP CUDA"
# Iterate over files in the input directory
for file in "$input_directory"/*; do
    if [ -f "$file" ]; then
    
        # Execute your pre-compiled executable file with the specified number of threads
        echo "Executing $executable_file in PARALLEL MODE"
        srun -n 1 "$executable_file" "$file" "0" 
        echo "Executing $executable_file in SEQUENTIAL MODE"
        srun -n 1 "$executable_file" "$file" "1" 
    fi
done

echo "Finished loop"

#print speedups and graphs
#python speedup.py "$PWD/CUDA/resultsCUDA" "$PWD/openMP/resultsOpenMP" "$PWD/graph_examples"
