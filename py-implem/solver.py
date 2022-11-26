import dependency_graph as dg
import base_graph as bg

UNLABELED_SER = 99999999
NO_BLOSSOM = -1

VERBOSE = False

class Transform(dg.Element):
    def __init__(self, tip1: dg.Element, tip2: dg.Element, bud: dg.Element):
        super().__init__(None)
        self.pair = tip1.pair

        self.bud = bud
        self.tip1 = tip1
        self.tip2 = tip2
        self.edge = (tip1, tip2)

class Property:
    def __init__(self, element: dg.Element):
        self.element = element

        self.serial: int = UNLABELED_SER
        self.previous: dg.Element = None
        self.reverse: dg.Element = None
        self.blossom_id = NO_BLOSSOM
        self.is_tip = False


def log(*args, **kwargs):
    if VERBOSE:
        print(*args, **kwargs)

class Solver:
    def __init__(self, dep_graph: dg.DependencyGraph):
        self.next_serial: int = 0
        self.next_element_id: int = max(dep_graph.elements.keys()) + 1
        self.next_blossom_id: int = 0
        self.blossoms: list[set[dg.Element]] = []

        self.dep_graph = dep_graph

        self.elem_properties: dict[dg.Element, Property] = {elem: Property(elem) for elem in self.dep_graph.elements.values()}

        self.queue: list[dg.Element] = []

    def _label_(self, elem: dg.Element, previous: dg.Element, reverse: dg.Element = None):
        self.elem_properties[elem].serial = self.next_serial
        self.next_serial += 1
        self.elem_properties[elem].previous = previous
        self.elem_properties[elem].reverse = reverse
        self.queue.append(elem)
        log('\t\t\tLabelled',elem,'with s:',self.next_serial-1, 'p:', previous)

    def _compute_transform_(self, bud: dg.Element, tip1: dg.Element, tip2: dg.Element):
        x = Transform(tip1, tip2, bud)
        x.element_id = self.next_element_id
        x.pair_id = x.tip1.pair_id
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
        log('\t\t\tCreated transform', x)
        log('\t\t\t  with adj:', ' '.join([str(e) for e in x.adjacency]))
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


    def _compute_search_path_(self, elem: dg.Element, detransform=False) -> list[dg.Element]:
        props = self.elem_properties[elem]
        if not isinstance(elem, Transform):
            if props.previous is None:
                return [elem]
            if props.reverse is not None:
                rev_path = self._compute_search_path_(props.reverse, detransform)
                rev_path = list(reversed(rev_path[:rev_path.index(elem)+1]))
                return rev_path + self._compute_search_path_(props.previous, detransform)
            else:
                return [elem, elem.pair] + self._compute_search_path_(props.previous, detransform)
        else:
            if props.reverse is None:
                return [elem.tip1 if detransform else elem, elem.pair] + self._compute_search_path_(props.previous, detransform)
            else:
                rev_path = self._compute_search_path_(props.reverse, detransform)
                rev_path = list(reversed(rev_path[:rev_path.index(elem.tip1)]))
                return [elem.tip1 if detransform else elem] + rev_path + self._compute_search_path_(props.previous, detransform)

    def _compute_primitive_bud_(self, elem1: dg.Element, elem2: dg.Element):
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
        path1 = self._compute_search_path_(elem1, detransform=True)
        path2 = self._compute_search_path_(elem2, detransform=True)
        for e in path1 + path2:
            if e.is_in_basis:
                e.is_in_basis = False
                self.dep_graph.basis.remove(e)
            else:
                e.is_in_basis = True
                self.dep_graph.basis.append(e)

    def _blossom_(self, elem1: dg.Element, elem2: dg.Element, root_bud: dg.Element):
        bud_blossom = self.elem_properties[root_bud].blossom_id
        path1 = self._compute_search_path_(elem1)
        path2 = self._compute_search_path_(elem2)

        bud1: dg.Element = None
        bud2: dg.Element = None
        bud1_index: int = -1
        bud2_index: int = -1

        for i, e in enumerate(path1):
            if (bud_blossom != NO_BLOSSOM and self.elem_properties[e] == bud_blossom) or e == root_bud:
                bud1 = e
                bud1_index = i
                break
        for i, e in enumerate(path2):
            if (bud_blossom != NO_BLOSSOM and self.elem_properties[e] == bud_blossom) or e == root_bud:
                bud2 = e
                bud2_index = i
                break
        
        tip1: dg.Element = None
        tip2: dg.Element = None

        if bud1 == bud2:
            tip1 = path1[bud1_index - 1]
            tip2 = path2[bud2_index - 1]
                
        to_label: dict[dg.Element, tuple[int, dg.Element, dg.Element]] = {}
        for i, e in enumerate(path1):
            if e == tip1 or e == bud1:
                break
            e_p = self.elem_properties[e]
            if e_p.serial != UNLABELED_SER:
                continue
            if e_p.blossom_id != NO_BLOSSOM and not e_p.is_tip:
                continue
            #previous = elem2 if i <= 1 else path1[i-2]
            to_label[e] = (self.elem_properties[e.pair].serial, elem1, elem2)
        for e in path2:
            if e == tip2 or e == bud2:
                break
            e_p = self.elem_properties[e]
            if e_p.serial != UNLABELED_SER:
                continue
            if e_p.blossom_id != NO_BLOSSOM and not e_p.is_tip:
                continue
            #previous = elem1 if i <= 1 else path2[i-2]
            to_label[e] = (self.elem_properties[e.pair].serial, elem2, elem1)
        
        label_list = sorted(to_label.keys(), reverse=True, key=lambda e: to_label[e][0])

        for g in label_list:
            g_p = self.elem_properties[g]
            if g_p.blossom_id != NO_BLOSSOM and not g_p.is_tip:
                continue
            self._label_(g, to_label[g][2], reverse=to_label[g][1])
            if g_p.is_tip:
                g_p.is_tip = False
                for e in self.elem_properties.keys():
                    if self.elem_properties[e].blossom_id == g_p.blossom_id:
                        self.elem_properties[e].is_tip = False
        
        new_blossom = []
        if tip1 is not None:
            x = self._compute_transform_(bud1, tip1, tip2)
            self._label_(x, elem2, reverse=elem1)
            new_blossom.append(x)
        
        for e in path1:
            if e == bud1:
                break
            new_blossom.append(e)
        for e in path2:
            if e == bud2:
                break
            new_blossom.append(e)
        if tip1 is not None:
            self.elem_properties[tip1].is_tip = True
            self.elem_properties[tip2].is_tip = True
        
        self._merge_into_blossom_(new_blossom)

    def improve_matching(self):
        log('Improving matching:', self.dep_graph.basis)
        if VERBOSE:
            print(self.dep_graph)
        # We label all singletons
        for singleton_id in self.dep_graph.singletons:
            singleton = self.dep_graph.elements[singleton_id]
            log('\tLabelling singleton', singleton)
            self._label_(singleton, None)

        while len(self.queue) > 0:
            current = self.queue.pop(0)
            current.adjacency.sort(key=lambda e: self.elem_properties[e].serial)
            log('\tScanning element', current)

            for adjacent in current.adjacency:
                # If the adjacent is equivalent to the current
                if self.elem_properties[adjacent].blossom_id != NO_BLOSSOM and self.elem_properties[adjacent].blossom_id == self.elem_properties[current].blossom_id:
                    continue

                if self.elem_properties[adjacent].serial != UNLABELED_SER and self.elem_properties[adjacent].serial < self.elem_properties[current].serial:
                    bud = self._compute_primitive_bud_(current, adjacent)
                    if bud is None:
                        log('\t\tAugment step/', current, adjacent)
                        self._augment_(current, adjacent)
                        return True
                    else:
                        log('\t\tBlossom step/ bud:', bud, 'x1:', current, 'x2:', adjacent)
                        self._blossom_(current, adjacent, bud)
                
                elif self.elem_properties[adjacent].serial == UNLABELED_SER and self.elem_properties[adjacent.pair].serial == UNLABELED_SER and self.elem_properties[adjacent].blossom_id == NO_BLOSSOM:
                    adjacent_pair = adjacent.pair
                    if adjacent_pair in current.adjacency:
                        log('\t\tDegenerate blossom step/ bud:', current, 'x1:', adjacent, 'x2:', adjacent_pair)
                        self._compute_degenerate_blossom_(current, adjacent, adjacent_pair)
                    else:
                        log('\t\tLabel step/', adjacent)
                        self._label_(adjacent_pair, current)
        
        return False