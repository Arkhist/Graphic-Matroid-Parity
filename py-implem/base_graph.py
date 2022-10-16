import networkx as nx

import union_find as uf

ELEMENT_ID_KEY = 'ELEMENT_ID_KEY'
PAIR_ID_KEY = 'PAIR_ID_KEY'

BaseEdge = tuple[int, int, dict[str, int]]


class BaseGraph:
    """
    This class is used as an interface with `networkx`,
    in the perspective of providing a library-less graph implementation.

    You should not use self.nx_instance if possible.
    """
    def __init__(self):
        self.nx_instance: nx.MultiGraph = None
        self.elements: dict[int, BaseEdge] = {}
        self.max_element_id = 0
    
    def init_instance(self, nx_instance=None):
        if not nx_instance:
            self.nx_instance = nx.MultiGraph()
        else:
            self.nx_instance = nx_instance
    
    def add_edge(self, u: int, v: int, edge_id: int):
        self.nx_instance.add_edge(u, v, ELEMENT_ID_KEY=edge_id, PAIR_ID_KEY=(edge_id)//2)
        self.elements[edge_id] = (u, v, {ELEMENT_ID_KEY: edge_id, PAIR_ID_KEY: (edge_id)//2})
        self.max_element_id = max(edge_id, self.max_element_id)
    
    def edges(self) -> list[BaseEdge]:
        return list(self.nx_instance.edges(data=True))
    
    def nodes(self) -> list[int]:
        return list(self.nx_instance.nodes())
    
    def adjacent_edges(self, edge: BaseEdge) -> list[BaseEdge]:
        return list(self.nx_instance.edges([edge[0], edge[1]], data=True))
    
    def get_edge(self, i: int) -> BaseEdge:
        pass
    
    def get_spanning_forest(self, matching: list[int] = None) -> None | tuple[list[BaseEdge], list[BaseEdge], dict[int, tuple[int, int]]]:
        """
        Get a spanning maximum forest of the graph

        Returns the forest, the elements not in the forest as well as a rooted representation
        """
        uf_set = list(range(max(list(self.nx_instance.nodes()))+1))
        if not matching:
            matching = []
        
        forest = []
        non_forest = []
        
        # Establish the base forest, with no singletons
        for edge in self.edges():
            if not edge[2][ELEMENT_ID_KEY] in matching:
                non_forest.append(edge)
            else:
                if uf.uf_find(uf_set, edge[0]) == uf.uf_find(uf_set, edge[1]):
                    return None # matching has cycle
                uf.uf_union(uf_set, edge[0], edge[1])
                forest.append(edge)
        
        next_singleton_id = self.max_element_id + 1

        # Add the singletons necessary to have a spanning forest
        for edge in self.edges():
            if uf.uf_find(uf_set, edge[0]) == uf.uf_find(uf_set, edge[1]):
                continue
            uf.uf_union(uf_set, edge[0], edge[1])
            singleton = (edge[0], edge[1], {ELEMENT_ID_KEY: next_singleton_id,  PAIR_ID_KEY: None})
            next_singleton_id = next_singleton_id + 1
            forest.append(singleton)

        # Compute a rooted forest representation by greedily doing Depth-First explorations
        remaining = self.nodes()
        edges_remaining = forest[:]
        parent = {}
        stack = []
        while len(remaining) > 0:
            root = remaining.pop()
            parent[root] = (root, None)
            stack.append(root)
            while len(stack) > 0:
                current = stack.pop()
                edges_to_remove = []
                for e in edges_remaining:
                    if not (e[0] == current or e[1] == current):
                        continue
                    endpoint = e[0] if e[1] == current else e[1]
                    
                    if endpoint in parent.keys():
                        continue

                    parent[endpoint] = (current, e[2][ELEMENT_ID_KEY])
                    stack.append(endpoint)
                    remaining.remove(endpoint)
                    edges_to_remove.append(e)
                for e in edges_to_remove:
                    edges_remaining.remove(e)

        return forest, non_forest, parent

            

        
