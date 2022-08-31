import dependency_graph as dg
import base_graph as bg

MASSIVE_INT = 99999999

class Transform(dg.Element):
    def __init__(self, blossom_edge: bg.BaseEdge, tip1: dg.Element, tip2: dg.Element, bud: dg.Element):
        dg.Element(blossom_edge)
        self.pair = tip1.pair

        self.bud = bud
        self.tip1 = tip1
        self.tip2 = tip2

class Property:
    def __init__(self, element: dg.Element):
        self.element = element

        self.serial: int = MASSIVE_INT
        self.previous: dg.Element = None
        self.blossom_id = 0

class Solver:
    def __init__(self, dep_graph: dg.DependencyGraph):
        self.next_serial: int = 0
        self.next_element_id: int = max(dep_graph.elements.keys()) + 1
        self.next_blossom_id: int = 0
        self.blossoms: list[set[Element]] = []

        self.dep_graph = dep_graph
        self.elem_properties: dict[Element] = {elem: Property(elem) for elem in self.dep_graph.elements}

    def improve_matching(self):
        queue: list[Element]