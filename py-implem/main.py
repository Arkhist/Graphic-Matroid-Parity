import input_parsing
import dependency_graph
import solver

if __name__ == "__main__":
    graph, matching_ids = input_parsing.read_base_graph_from_stsh_input()

    dep_graph = dependency_graph.DependencyGraph(graph, matching_ids)
    sol = solver.Solver(dep_graph)
    while sol.improve_matching():
        matching_ids = dep_graph.get_matching_from_basis()
        dep_graph = dependency_graph.DependencyGraph(graph, matching_ids)
        sol = solver.Solver(dep_graph)
    
    print(sorted(matching_ids))