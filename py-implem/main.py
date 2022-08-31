import input_parsing
import dependency_graph

if __name__ == "__main__":
    graph, matching_ids = input_parsing.read_base_graph_from_stsh_input()
    dep_graph = dependency_graph.DependencyGraph(graph, matching_ids)
    print(dep_graph)