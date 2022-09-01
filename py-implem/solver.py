import dependency_graph as dg
import base_graph as bg

UNLABELED_SER = 99999999
NO_BLOSSOM = -1

class Transform(dg.Element):
    def __init__(self, blossom_edge: bg.BaseEdge, tip1: dg.Element, tip2: dg.Element, bud: dg.Element):
        super().__init__(blossom_edge)
        self.pair = tip1.pair

        self.bud = bud
        self.tip1 = tip1
        self.tip2 = tip2

class Property:
    def __init__(self, element: dg.Element):
        self.element = element

        self.serial: int = UNLABELED_SER
        self.previous: dg.Element = None
        self.blossom_id = NO_BLOSSOM

class Solver:
    def __init__(self, dep_graph: dg.DependencyGraph):
        self.next_serial: int = 0
        self.next_element_id: int = max(dep_graph.elements.keys()) + 1
        self.next_blossom_id: int = 0
        self.blossoms: list[set[dg.Element]] = []

        self.dep_graph = dep_graph

        self.elem_properties: dict[dg.Element, Property] = {elem: Property(elem) for elem in self.dep_graph.elements.values()}

        self.queue: list[dg.Element] = []

    def _label_(self, elem: dg.Element, previous: dg.Element):
        self.elem_properties[elem].serial = self.next_serial
        self.next_serial += 1
        self.elem_properties[elem].previous = previous
        self.queue.append(elem)

    def _compute_degenerate_blossom_(self, bud: dg.Element, tip1: dg.Element, tip2: dg.Element):
        raise NotImplementedError('not done yet')
        pass

    def _compute_search_path_(self, elem: dg.Element) -> list[dg.Element]:
        if isinstance(elem, Transform):
            elem = elem.tip1
        path: list[dg.Element] = [elem]
        if self.elem_properties[elem].previous is None:
            return path
        path.append(elem.pair)
        return path + self._compute_search_path_(self.elem_properties[elem].previous)

    def _compute_primitive_bud_(self, elem1: dg.Element, elem2: dg.Element):
        bud: dg.Element = None

        path1 = self._compute_search_path_(elem1)
        path2 = self._compute_search_path_(elem2)

        for b in path1:
            blossom = None if self.elem_properties[b].blossom_id == NO_BLOSSOM else self.blossoms[self.elem_properties[b].blossom_id]
            for x in path2:
                if blossom is None:
                    if b == x:
                        return b
                elif x in blossom:
                    return b
        return None

    def _augment_(self, elem1: dg.Element, elem2: dg.Element):
        path1 = self._compute_search_path_(elem1)
        path2 = self._compute_search_path_(elem2)
        for e in path1 + path2:
            if e.is_in_basis:
                e.is_in_basis = False
                self.dep_graph.basis.remove(e)
            else:
                e.is_in_basis = True
                self.dep_graph.basis.append(e)

    def _blossom_(self, elem1: dg.Element, elem2: dg.Element, root_bud: dg.Element):
        raise NotImplementedError('not done yet')
        pass

    def improve_matching(self):
        # We label all singletons
        for singleton_id in self.dep_graph.singletons:
            singleton = self.dep_graph.elements[singleton_id]
            self._label_(singleton, None)

        while len(self.queue) > 0:
            current = self.queue.pop(0)
            current.adjacency.sort(key=lambda e: self.elem_properties[e].serial)

            for adjacent in current.adjacency:
                # If the adjacent is equivalent to the current
                if self.elem_properties[adjacent].blossom_id != NO_BLOSSOM and self.elem_properties[adjacent].blossom_id == self.elem_properties[current].blossom_id:
                    continue
                

                if self.elem_properties[adjacent].serial != UNLABELED_SER and self.elem_properties[adjacent].serial < self.elem_properties[current].serial:
                    bud = self._compute_primitive_bud_(current, adjacent)
                    if bud is None:
                        self._augment_(current, adjacent)
                        return True
                    else:
                        self._blossom_(current, adjacent, bud)
                
                elif self.elem_properties[adjacent].serial == UNLABELED_SER and self.elem_properties[adjacent.pair].serial == UNLABELED_SER and self.elem_properties[adjacent].blossom_id == NO_BLOSSOM:
                    adjacent_pair = adjacent.pair
                    if adjacent_pair in current.adjacency:
                        self._compute_degenerate_blossom_(current, adjacent, adjacent_pair)
                    else:
                        self._label_(adjacent_pair, current)
        
        return False