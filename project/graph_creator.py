import random
import sys
 
V = int(sys.argv[1])
total_edges = int(sys.argv[2])
file_name = "example"

print(len(sys.argv))

if len(sys.argv) == 4:
    file_name += str(sys.argv[3]) + ".txt"
else:
    file_name += "0.txt"
# need 3 things Number of vertices, edges and the various connections

f = open(file_name, "w")

E = 0
f.write(f"{V}\n")

count = 0
seen = set()
string = ""
while count != total_edges:
    node1 = random.randint(0,V)
    node2 = random.randint(0,V)
    
    if node1 != node2 and (node1, node2) not in seen:
        weight = random.randint(0,100)
        seen.add((node1,node2))
        string += str(node1)+" "+str(node2)+" "+str(weight)+"\n"
        count += 1
        E += 1

f.write(f"{E}\n")

f.write(f"{string}")
f.close()        

