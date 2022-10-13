import dependency_graph as dg
import base_graph as bg

UNLABELED_SER = 99999999
NO_BLOSSOM = -1

class Transform(dg.Element):
    def __init__(self, tip1: dg.Element, tip2: dg.Element, bud: dg.Element):
        super().__init__(None)
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
        self.is_tip = False

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

    def _compute_transform_(self, bud: dg.Element, tip1: dg.Element, tip2: dg.Element):
        x = Transform(tip1, tip2, bud)
        x.element_id = self.next_element_id
        self.dep_graph.add_element(self.next_element_id, x)
        self.next_element_id += 1
        
        for a in tip1.adjacency:
            if a in tip2.adjacency:
                continue
            self.dep_graph.make_adjacent(x, a)
        for a in tip2.adjacency:
            if a in tip1.adjacency:
                continue
            self.dep_graph.make_adjacent(x, a)
        
        self.elem_properties[x] = Property(x)
        return x
    
    def _merge_into_blossom_(self, ebunch: list[dg.Element]):
        new_blossom: set[dg.Element] = set(ebunch)
        blossoms_to_merge = [self.elem_properties[e].blossom_id for e in ebunch if self.elem_properties[e].blossom_id != NO_BLOSSOM]
        for e in ebunch:
            self.elem_properties[e].blossom_id = self.next_blossom_id

        for blossom in blossoms_to_merge:
            for e, p in self.elem_properties.items():
                if p.blossom_id == blossom:
                    new_blossom.add(e)
                    p.blossom_id = self.next_blossom_id
        
        self.next_blossom_id += 1
        self.blossoms.append(new_blossom)
        

    def _compute_degenerate_blossom_(self, bud: dg.Element, tip1: dg.Element, tip2: dg.Element):
        x = self._compute_transform_(bud, tip1, tip2)
        self._merge_into_blossom_([tip1, tip2, x])
        self.elem_properties[tip1].is_tip = True
        self.elem_properties[tip2].is_tip = True
        self._label_(x, bud)


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
        bud_blossom = self.elem_properties[root_bud].blossom_id
        p1 = self._compute_search_path_(elem1)
        p2 = self._compute_search_path_(elem2)

        b1: dg.Element = None
        b2: dg.Element = None
        b1_i: int = -1
        b2_i: int = -1

        for i, e in enumerate(p1):
            if (bud_blossom != NO_BLOSSOM and self.elem_properties[e] == bud_blossom) or e == root_bud:
                b1 = e
                b1_i = i
                break
        for i, e in enumerate(p2):
            if (bud_blossom != NO_BLOSSOM and self.elem_properties[e] == bud_blossom) or e == root_bud:
                b2 = e
                b1_i = i
                break
        
        t1: dg.Element = None
        t2: dg.Element = None

        if b1 == b2:
            t1 = p1[b1_i - 1]
            t2 = p2[b2_i - 1]
        
        to_label: dict[dg.Element, tuple[int, dg.Element]] = {}
        for i, e in enumerate(p1):
            if e == t1 or e == b1:
                break
            e_p = self.elem_properties[e]
            if e_p.serial != UNLABELED_SER:
                continue
            if e_p.blossom_id != NO_BLOSSOM and not e_p.is_tip:
                continue
            previous = elem2 if i <= 1 else p1[i-2]
            to_label[e] = (self.elem_properties[e.pair].serial, previous)
        for e in p2:
            if e == t2 or e == b2:
                break
            e_p = self.elem_properties[e]
            if e_p.serial != UNLABELED_SER:
                continue
            if e_p.blossom_id != NO_BLOSSOM and not e_p.is_tip:
                continue
            previous = elem1 if i <= 1 else p2[i-2]
            to_label[e] = (self.elem_properties[e.pair].serial, previous)
        
        label_list = sorted(to_label.keys(), reverse=True, key=lambda e: to_label[e][0])

        for g in label_list:
            g_p = self.elem_properties[g]
            if g_p.blossom_id != NO_BLOSSOM and not g_p.is_tip:
                continue
            self._label_(g, to_label[g][1])
            if g_p.is_tip:
                g_p.is_tip = False
                for e in self.elem_properties.keys():
                    if self.elem_properties[e].blossom_id == g_p.blossom_id:
                        self.elem_properties[e].is_tip = False
        
        if t1 is not None:
            x = self._compute_transform_(b1, t1, t2)
            self._label_(x, t1.pair)
        
        new_blossom = []
        for e in p1:
            if e == b1:
                break
            new_blossom.append(e)
        for e in p2:
            if e == b2:
                break
            new_blossom.append(e)
        if t1 is not None:
            self.elem_properties[t1].is_tip = True
            self.elem_properties[t2].is_tip = True
        
        self._merge_into_blossom_(new_blossom + [x])

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