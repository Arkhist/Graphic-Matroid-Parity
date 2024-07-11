import sys
import base_graph

class Element:
    def __init__(self, edge: base_graph.BaseEdge):
        self.adjacency: list[Element] = []
        self.edge = edge

        if not self.edge is None:
            self.element_id: int = edge[2][base_graph.ELEMENT_ID_KEY]
            self.pair_id: int = edge[2][base_graph.PAIR_ID_KEY]
        self.pair: Element = None
        
        self.is_in_basis = False
        self.is_meta = False

    def __str__(self) -> str:
        return f'e{self.element_id},p{self.pair_id}-({self.edge[0] if self.edge is not None else "x"}, {self.edge[1] if self.edge is not None else "x"})' + ('s' if self.is_meta else '')

    def __repr__(self) -> str:
        return f'(elem: {self.element_id}, pair: {self.pair_id}{", base" if self.is_in_basis else ""}{", s" if self.is_meta else ""})'
    
    def __hash__(self) -> int:
        return self.element_id

    def edge_adjacent(self, other) -> bool:
        return self.edge[0] == other.edge[0] or self.edge[0] == other.edge[1] or self.edge[1] == other.edge[0] or self.edge[1] == other.edge[1]
    
    def is_element_parallel(self, other) -> bool:
        return (self.edge[0] == other.edge[0] and self.edge[1] == other.edge[1]) or (self.edge[0] == other.edge[1] and self.edge[1] == other.edge[0])

def edge_to_element_id(edge: base_graph.BaseEdge):
    return edge[2][base_graph.ELEMENT_ID_KEY]

def edge_to_pair_id(edge: base_graph.BaseEdge):
    return edge[2][base_graph.PAIR_ID_KEY]


class DependencyGraph:
    def __init__(self, graph: base_graph.BaseGraph, matching: list[int] = None):
        if not matching:
            matching = []

        self.basis: list[Element] = []
        
        self.elements: dict[int, Element] = {}
        self.singletons = []
        self.pairs: list[list[Element]] = [[None, None] for i in range(len(graph.edges())//2)]
        for edge in graph.edges():
            e = Element(edge)
            self.add_element(edge_to_element_id(edge), e)
            self.pairs[edge_to_pair_id(edge)][edge[2][base_graph.ELEMENT_ID_KEY] % 2] = e
        
        for pair in self.pairs:
            pair[0].pair = pair[1]
            pair[1].pair = pair[0]
        
        self._compute_adj_(graph, matching)
        
    def make_adjacent(self, elem1: Element, elem2: Element):
        elem1.adjacency.append(elem2)
        elem2.adjacency.append(elem1)
    
    def add_element(self, key: int, elem: Element):
        if key in self.elements.keys():
            raise RuntimeError('trying to add an element with an already existing id')
        self.elements[key] = elem
    
    def get_matching_from_basis(self) -> list[int]:
        matching: list[int] = []
        for e in self.basis:
            if e.is_meta:
                continue
            matching.append(e.element_id)
        matching = sorted(matching)

        # Assertion: the matching must be pairs
        if len(matching) % 2 != 0 or not all((x+1 in matching) if x % 2 == 0 else (x-1 in matching) for x in matching):
            raise AssertionError("computed matching isn't pairs", matching)
        
        return matching

    def _compute_adj_(self, graph: base_graph.BaseGraph, matching: list[int]):
        """
        Computes the adjacencies of each element of the graph.
        We do this by finding the elementary cycle created when adding a non-basis edge to the forest, for all such edges.
        This is done through the use of a rooted representation of the forest provided by the base graph object.
        """
        basis_edges, n_b, parent_forest = graph.get_spanning_forest(matching)
        non_basis: list[Element] = [self.elements[edge_to_element_id(n)] for n in n_b]

        # add singletons as elements
        for e in basis_edges:
            eid = edge_to_element_id(e)
            if not eid in self.elements.keys():
                self.elements[eid] = Element(e)
                self.singletons.append(eid)
                self.elements[eid].is_meta = True
            self.elements[eid].is_in_basis = True
            self.basis.append(self.elements[eid])

        for e in non_basis:
            # Backtracking to find the cycle with e = (u,v)
            current = e.edge[0]

            # We build the path from u to r (root of current tree)
            backtrack_first: list[Element | int] = [current]
            while parent_forest[current][0] != current:
                backtrack_first += [parent_forest[current][1], parent_forest[current][0]]
                current = parent_forest[current][0]
            
            # We then 
            backtrack_second: list[Element] = []
            current = e.edge[1]
            while True:
                for i, v in enumerate(backtrack_first):
                    if i % 2 != 0:
                        continue
                    if v != current:
                        continue
                    # backtracking
                    for elem2_id in backtrack_second:
                        self.make_adjacent(e, self.elements[elem2_id])
                    for j in range(i-1, -1, -2):
                        self.make_adjacent(e, self.elements[backtrack_first[j]])
                    break # Quit both loops
                else:
                    if parent_forest[current][1] is None:
                        raise RuntimeError('infinite loop at backtracking CCA')
                    backtrack_second.append(parent_forest[current][1])
                    current = parent_forest[current][0]
                    continue
                break
    
    def __str__(self) -> str:
        lines = []
        for e in self.elements.values():
            if e.is_in_basis:
                lines.append('\t\t' + str(e) + ': ' + ', '.join([str(x) for x in e.adjacency]))
        return '\n'.join(lines)
                        

                        




        

        