import networkx as nx

class Graph:
    """
    This class is used as an interface with `networkx`,
    in the perspective of providing a library-less graph implementation.

    You should not use self.nx_instance if possible.
    """
    def __init__(self):
        self.nx_instance: nx.Graph = None
    
    def init_instance(self, nx_instance=None):
        if not nx_instance:
            self.nx_instance = nx.Graph()
        else:
            self.nx_instance = nx_instance
    
    def add_edge(u: int, v: int, _id: int):
        self.nx_instance.add_edge(u, v, id=_id)
