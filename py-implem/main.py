import input_parsing
import dependency_graph
import solver

"""
Python implementation of Stallmann's algorithm for Graphic Matroid Parity

Benjamin Peyrille - 2022
"""

if __name__ == "__main__":
    graph, matching_ids = input_parsing.read_base_graph_from_stsh_input()

    print('Input matching size', len(matching_ids))

    dep_graph = dependency_graph.DependencyGraph(graph, matching_ids)
    sol = solver.Solver(dep_graph)
    print('\tIntermediary matching:', matching_ids)
    while sol.improve_matching():
        matching_ids = dep_graph.get_matching_from_basis()
        print('\tIntermediary matching:', matching_ids)
        dep_graph = dependency_graph.DependencyGraph(graph, matching_ids)
        sol = solver.Solver(dep_graph)
    
    print('Final matching size:', len(matching_ids))
    print(sorted(matching_ids))