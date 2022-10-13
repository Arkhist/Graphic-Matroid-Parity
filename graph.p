
{ **** graph.i **** }
{ This module implements the data type GRAPH.
   A GRAPH consists of a number of entities called vertices,
   related in a pairwise manner by entities called edges.
   Two vertices related by an edge are said to be adjacent vertices.
   We will speak of the edge relating two vertices as the edge 
   between the vertices.

   The vertices are indexed by the ordinal type VERTEX, defined as 1..MAXV.
   The user must set the constant MAXV. 
   The type VERTEX is provided to the user.

The following operations can be performed on a GRAPH:
    1. InitGr (var g: GRAPH; n: integer)
	Initializes g to be a graph with no edges on n vertices.
    2. EraseGr(var g: GRAPH)
	Removes all edges from g
    3. AddEdgeGr (var g: GRAPH; v1,v2: VERTEX)
	Adds an edge between vertices v1 and v2.
    4. CopyGr( g1:GRAPH; var g2: GRAPH);
	Places a copy of g1 into g2. The copies are independent; one can be
	manipulated without changing the other.
	g2 is a returned parameter; it need not be initialized before calling 
	CopyGr.
    5. ForAdjGr (g: GRAPH; v: VERTEX; procedure P(u: VERTEX))
	For each vertex u adjacent to v in g, perform P.
    6. ForVertex(g:GRAPH, procedure P(v: VERTEX))
	For each vertex v in g, do P.
    
    Other operations on a GRAPH may be added in other modules which
    use the above basic operations.    
					   }
procedure EraseGr(var g: GRAPH);
    { This procedure empties the adjacency list for each vertex,
      leaving the graph in the empty state.    }

  var cur,nxt: aptr;
      i: integer;
  begin
    for i:= 1 to g.numVertex do begin
    {D writeln(' clear adjacency list for vertex', i);   }
      cur:= g.adjacency[i];
      g.adjacency[i]:= nil;
      while cur <> nil do begin
	nxt:= cur^.next;
	dispose(cur);
	cur:= nxt;
      end; (* while *)
    end; (* for *)
  end; (* Erase Gr *)


procedure InitGr(var g:GRAPH; n: integer);
  begin
  {T writeln(' entered INIT GR, number of nodes is', n);  }
    { check the input parameter n }
    if n > MAXV then begin
      writeln(' input number of vertices ',n,
     	      ' exceeds maximum allowable of ',MAXV);
      halt;
    end; (* if *)
    if n < 1 then begin
	writeln(' input number of vertices ',n,
		' is not valid');
	halt;
    end; (* if *)
    { end check n }
    g.numVertex:= n;
    EraseGr(g);
  {T writeln(' exit INIT GR');   }
 end; (* Init Gr *)

procedure AddEdgeGr (var g: GRAPH; u,v: VERTEX);
     { This procedure adds v to u's adjacency list, and vice versa }
  var ap: aptr;

  begin
 {D writeln(' enter ADD EDGE GR with vertices', u,v);  }
   new(ap);
   ap^.vnum:= v;
   ap^.next:= g.adjacency[u];
   g.adjacency[u]:= ap;
     { and vice versa }
   new(ap);
   ap^.vnum:= u;
   ap^.next:= g.adjacency[v];
   g.adjacency[v]:= ap;
  end; (* Add Edge Gr *)

procedure ForAdjGr ( g: GRAPH; u:VERTEX; procedure P( v:VERTEX));
  var
    ap: aptr;
  begin
    ap:= g.adjacency[u];
    while ap <> nil do begin
      P( ap^.vnum);
      ap:= ap^.next;
    end; (* while *)
  end; (* For Adjacent in Graph *)

procedure ForVertex( g: GRAPH; procedure P(v: VERTEX));
  var
    v: VERTEX;
  begin
  {D writeln(' enter FOR VERTEX');   }
    for v:= 1 to g.numVertex do 
      P(v);
  {D writeln(' exit FOR VERTEX');}
  end;  (* For Vertex *)


procedure CopyGr(g1: GRAPH; var g2: GRAPH);
  { This procedure places a copy of g1 into g2 }

  procedure copyAdjList(u: VERTEX);
    { This procedure copies the adjacency list of vertex u from g1 to g2 }
    
    var
      g1ptr, g2node: aptr;
    begin (* copy Adj List *)
      g1ptr:= g1.adjacency[u];
      while g1ptr <> nil do begin
	new(g2node);
	g2node^.vnum:= g1ptr^.vnum;
	g2node^.next:= g2.adjacency[u];
	g2.adjacency[u]:= g2node;
	g1ptr:= g1ptr^.next;
      end; (* while *)
    end; (* Copy Adj List *)
  
  begin (* Copy Graph *)
    InitGr(g2, g1.numVertex);
    ForVertex(g1, copyAdjList);
  end; (* Copy Graph *)


 procedure PrintAdjList(g: GRAPH);
      (* this routine is used for debug purposes only *)

    var ap:aptr;
        i: integer;
    begin
      writeln(' entered PRINT ADJ LIST'); 
      for i:= 1 to g.numVertex do begin
	write('adjacency list for vertex ',i);
	ap:= g.adjacency[i];
	while ap <> nil do begin
	  write (ap^.vnum);
	  ap:= ap^.next;
	end; (* while *)
        writeln;
      end; (* for *)
      writeln(' exited PRINT ADJ LIST');
    end; (* print_adj_list *)            
