import base_graph
import sys

def read_base_graph_from_stsh_input() -> tuple[base_graph.BaseGraph, list[int]]:
    """
    Input format follows from Stallmann & Shapiro's (1986) implementation input:

    [vertex amount]
    [x1 y1]
    [x2 y2]
    ...
    [xn yn]
    0 0
    [e1]
    [e2]
    ...
    [ek]
    0
    """

    result = base_graph.BaseGraph()
    edges_to_add = []
    edges_added = 0
    matching = []

    input() # Dump first line


    # Read edges
    try:
        x, y = [int(e) for e in input().split(' ')]
        while x > 0 and y > 0:
            edges_to_add.append((x-1, y-1, edges_added))
            edges_added += 1
            x, y = [int(e) for e in input().split(' ')]
    # Edge reading error handling
    except ValueError:
        print('Input is malformed: edge entry is not two vertices \'x y\'', file=sys.stderr)
        return None
    if x != 0 or y != 0:
        print('Input is malformed: edge separation is not \'0 0\'.', file=sys.stderr)
        return None
    if edges_added % 2 != 0:
        print('Input is incomplete: need an even amount of edges.', file=sys.stderr)
        return None

    # Read matching
    try:
        e = int(input())
        while e > 0:
            matching.append(e-1)
            e = int(input())
        matching.sort()
    # Matching reading error handling
    except ValueError:
        print('Input is malformed: matching edge given is not a number')
        return None
    if len(matching) % 2 != 0:
        print('Input is incomplete: matching needs an even amount of edges')
        return None
    for i in range(0, len(matching), 2):
        if matching[i]+1 != matching[i+1] or matching[i] > edges_added or matching[i] < 0:
            print('Input is wrong: matching provided is invalid')
            return None

    result.init_instance()
    for edge in edges_to_add:
        result.add_edge(edge[0], edge[1], edge[2])
    
    return result, matching
    
