import sys
import os
import matplotlib.pyplot as plt

def readCUDA(f):
    lines = f.readlines()
    
    speedParallel = float(lines[0].split(':')[2][:-1])
    speedSequential = float(lines[1].split(':')[1][:-1])
    
    return [speedParallel, speedSequential]
        
    
def readOpenMP(f):
    lines = f.readlines()
    
    speeds = []
    for line in lines:
        speeds.append(float(line.split(':')[2][:-1]))
        
    return speeds

def getVertices(f):
    return f.readlines()[1][:-1]

def main():
    if len(sys.argv) < 2:
        print("Invalid number of arguments")
        exit()
    
    # this gets rid of nuances of paths written in different types of OS
    pathCUDA = sys.argv[1]
    pathOpenMP = sys.argv[2]
    pathExamples = sys.argv[3]
    
    if os.name == 'nt':
        delimeter = '\\'
    else:
        delimeter = '/'    
        
    dir_list_CUDA = os.listdir(pathCUDA)
    dir_list_openMP = os.listdir(pathOpenMP)
    dir_list_examples = os.listdir(pathExamples)
    
    speedsCuda = []
    speedsOpenMP = []
    
    vertices = []
    edges = []
    
    for f in dir_list_examples:
        curr_file = pathExamples + delimeter + f
        file = open(curr_file,"r")
        vertices.append(file.readline()[:-1])
        edges.append(file.readline()[:-1])    
        file.close()

    print(vertices,edges)
    
    for f in dir_list_CUDA:
        curr_file = pathCUDA + delimeter + f
        speedsCuda.append(readCUDA(open(curr_file,"r")))
        
    for f in dir_list_openMP:
        curr_file = pathOpenMP + delimeter + f
        speedsOpenMP.append(readOpenMP(open(curr_file,"r")))
    
    maxThreads = 2**(len(speedsOpenMP[0])-1)
    threads = [2**i for i in range(len(speedsOpenMP[0]))]
    print(maxThreads, threads)
    
    speedupsCUDA = []
    
    for i in range(len(speedsCuda)):
        speedup = speedsCuda[i][1] / speedsCuda[i][0]
        print(f"Example_{i+1}:")
        print(f"Sequential time: {speedsCuda[i][1]}")
        print(f"Parallel time: {speedsCuda[i][0]}")
        print(f"Speedup: {speedup}\n")
        speedupsCUDA.append(speedup)
        
    speedupsOpenMP = []
    # the speedup for openMP will be computed for 4 threads (since slurm machines have 4 cores, it is the biggest speedup)
    for i in range(len(speedsOpenMP)):
        curr_speedup = []
        for j in range(len(speedsOpenMP[0])):
            if speedsOpenMP[i][0] == 0.0:
                speedsOpenMP[i][0] = 0.00001

            speedup = speedsOpenMP[i][0] / speedsOpenMP[i][j]
            
            if j == 2:
                print(f"Example_{i+1}:")
                print(f"Sequential time: {speedsOpenMP[i][0]}")
                print(f"Parallel time: {speedsOpenMP[i][2]}")
                print(f"Speedup: {speedup}\n")
            
            curr_speedup.append(speedup)
        speedupsOpenMP.append(curr_speedup)
    
    print(speedupsOpenMP)
    
    #PLOTTING
    
    #CUDA SPEEDUP
    plt.plot(vertices,speedupsCUDA,marker='o')
    plt.title('Speedup CUDA')
    plt.xlabel('Number of Vertices')
    plt.ylabel('Speedup')
    plt.show()
    
    plt.plot(edges,speedupsCUDA,marker='o')
    plt.title('Speedup CUDA')
    plt.xlabel('Number of Edges')
    plt.ylabel('Speedup')
    plt.show()
    
    #OPENMP SPEEDUP
    plt.plot(vertices,[speedupsOpenMP[i][2] for i in range(len(speedupsOpenMP))],marker='o')
    plt.title('Speedup OpenMP')
    plt.xlabel('Number of Vertices')
    plt.ylabel('Speedup')
    plt.show()
    
    plt.plot(edges,[speedupsOpenMP[i][2] for i in range(len(speedupsOpenMP))],marker='o')
    plt.title('Speedup OpenMP')
    plt.xlabel('Number of Edges')
    plt.ylabel('Speedup')
    plt.show()
    
    #OPENMP ELAPSED TIME FOR DIFFERENT NUMBER OF THREADS
    fig, axs = plt.subplots(1, 5, figsize=(15, 5))

    # Add title for the whole subplot
    fig.suptitle('Elapsed time for different number of threads', fontsize=16)
    for i, ax in enumerate(axs.flatten()):
        ax.plot(threads, speedsOpenMP[i], marker='o', linestyle='-')
        ax.set_title(f'Example_{i+1}')
        ax.set_xlabel('Number of Threads')
        ax.set_ylabel('Elapsed time')

    plt.tight_layout()
    plt.show()
    
    #OPENMP SPEEDUP FOR DIFFERENT NUMBER OF THREADS
    fig, axs = plt.subplots(1, 5, figsize=(15, 5))

    fig.suptitle('Speedup for different number of threads', fontsize=16)
    for i, ax in enumerate(axs.flatten()):
        ax.plot(threads, speedupsOpenMP[i], marker='o', linestyle='-')
        ax.set_title(f'Example_{i+1}')
        ax.set_xlabel('Number of Threads')
        ax.set_ylabel('Speedup')

    plt.tight_layout()
    plt.show()
    
if __name__ == '__main__':
    main()