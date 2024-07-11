
  { **** spforest.i **** }
  { This module implements a spanning forest on a graph.

    The spanning forest is stored in a variable of type FOREST.
    FOREST maintains two arrays, 'pre' and 'high', both indexed by
    the ordinal type VERTEX. VERTEX must be defined in the module which
    implements the graph.

    'pre' stores the pre-order number of a node in the spanning forest.
    'high' stores the highest descendant of a vertex in the spanning
     forest.
     The spanning forest is calculated by recursive calls to the routine 
     search, which implements a depth first search.

     The module which implements a graph must provide the following routines:
	ForVertex( g:GRAPH, procedue P(v:VERTEX));
	  This procedure performs P on every vertex v in g.
	
	ForAdjGr( g:GRAPH; u:VERTEX, procedure P(v:VERTEX))
	  This procedure performs P for every vertex v adjacent to u in g.

     The following operations can be performed on a spanning tree:
       
       1. InitSpForest( g:GRAPH; t:FOREST, procedure P(u,v:VERTEX))
	   This procedure initializes t to be a spanning forest for g.
	   t is a "returned" parameter from InitSpForest, in that
	   t is not defined when InitSpForest is called.
	   The procedure P is performed for every tree edge u,v in the 
	   spanning forest.

       2. IsInCycle(v,w,x,y:VERTEX; t:FOREST): boolean;
	   true if tree edge v,w is in the fundamental cycle formed when
	   edge x,y is added to the spanning tree t.

	   ********** NOTE *******
	       IsInCycle does not check that v,w is an edge in the forest.

                                                                            }

  procedure InitSpForest(g:GRAPH; var t:FOREST; procedure P(u,v:VERTEX));

    var
      visited: array [VERTEX] of boolean;   { indicator array }
      dfsn: integer;     { global to search for assigning PRE }

  function search(node: VERTEX): integer;
    { search is called recusivly to perform a depth first search.
      The input parameter is the current node in the search.
      search returns the highest pre-order number of a descendent
      of the input node.   }
   
    procedure continueSearch( v: VERTEX);
      begin
	 {D writeln(' enter CONTINUE SEARCH with node',v);}
	if not visited[v] then begin
	  { do P to the edge node,v }
	  P(node,v);
	  t.high[node]:= search(v);
	end; (* if *)
      end; (* Continue Search *)

    begin  (* Search *)
       {D writeln (' entered search with node ',node);  }
      visited[node]:= true;
      dfsn:= dfsn + 1;
      t.pre[node]:= dfsn;
      t.high[node]:= dfsn;
       {D writeln(' pre-order number of node is ',dfsn);   }

      ForAdjGr( g, node, continueSearch); {  search through adjacency list }

      search:= t.high[node];
       {D writeln(' HIGH set to ',t.high[node],' for node ',node); }
    end; (* Search *)

  procedure rootIfNotVisited( v: VERTEX);
    begin
     {D writeln(' entered ROOT IF NOT VISITED with vertex', v);  }
      if not visited[v] then
	t.high[v]:= search(v);
    end; (* Root etc *)

  procedure initialVisited( v: VERTEX );
    begin
      visited[v]:= false;
    end;

  begin (* InitSpForest *)
   { initialize  }
    dfsn:= 0;
    ForVertex( g, initialVisited);
    { end initialization }
    ForVertex( g,rootIfNotVisited);
  end; (* Initialize Spanning Forest *)
   


function IsInCycle( v,w,x,y: VERTEX; t: FOREST): boolean;
   { this function returns true if edge (v,w) is in the fundamental 
     cycle formed by adding edge (x,y) to the forest t }

 var
   lim1, lim2: integer;    { used to test cycle condition }
 
 function btwn( a: integer): boolean;
    { returns true if lim1 <= a <= lim2   }
   begin
     if (lim1 <= a) and (lim2 >= a) then 
       btwn:= true
     else
       btwn:= false;
   end; (* btwn *)

  begin
    with t do begin
      if pre[v] < pre[w] then begin
	lim1:= pre[w];
	lim2:= high[w];
       end
      else begin
	lim1:= pre[v];
	lim2:= high[v];
      end; (* if *)
  { check cycle condition   }
      IsInCycle:= btwn(pre[x]) <> btwn(pre[y]);
    end;  (* with t *)
  end; (* IsInCycle  *)


 procedure PrintSpForest(g:GRAPH; t: FOREST);
     (* This routine prints the pre and high numbers for the forest t,
	 of graph g.
	 It is used for debugging only.   *)
     var j: integer;
     begin
       writeln(' spanning tree has pre and high as follows');
       writeln(' pre:');
       for j:= 1 to g.numVertex do
	 write(t.pre[j]);
       writeln;
       writeln(' high:');
       for j:= 1 to g.numVertex do
	 write(t.high[j]);   
       writeln; 
     end; 
