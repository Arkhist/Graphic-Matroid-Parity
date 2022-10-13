{ **** parpgm.p **** }
program maxpar(input,output);


{ **** userGlob.i **** }
{ This module contains all global type and variable decalrations which 
  depend upon the specific matroid or upon the implementation of required
  support modules, (see heading comments in parpgm.p). }

const
   NULLELEMENT = 0;     
   MAXE        = 1000;           { maximum number of elements in a matroid , }
   { including transforms and singletons.      }
   LOGMAXELEMENTS = 10;	{ log to the base 2 of # of elements }
   MAXDIGIT = 3;         { the maximum numbe of digits used to repesent
                         an element. Used in output routines }
   MAXV = 10000;            { maximum number of vertices in a graph }
   MAXRANK = 9999;         { maximum rank of an input matroid }
   DELIM = '$';          { this delimiter appears around each element
                         number in the output }
type
  ELEMENT = 0..MAXE;   { ordinal type for matroid elements }
  VERTEX = 1..MAXV;    { ordinal type for vertices in graph module }
  EPTR = ^eltype;
   { "eltype" is a record describing the matroid elements. } 
  elcases = (normal, transform);  { two kinds of elements }  
  eltype = record
              case elcases of
                normal : (end1, end2: VERTEX); { endpoints of edge }
                transform : (el1, el2: ELEMENT); { tips of transform }
              end;        
  QDATA = ELEMENT;     { type definition for items to be enqueued }
  INDICATOR = array [ELEMENT] of boolean; 
  { used for passing parameters to output routine }
  
  { the following types are used to implement a graph  }
  aptr = ^adjNode;
  adjNode = record       { node on adjacency list }
              vnum : VERTEX; { number of vertex on list }
              next : aptr;     { pointer }
            end; (* adj_node *)
  GRAPH = record
            numVertex : integer;
            adjacency : array [VERTEX] of aptr;
          end;  (* GRAPH *)

  { the type FOREST is used to implement a spanning tree - see spforest.i, below }
  FOREST = record
    pre: array [VERTEX] of integer;
    high: array [VERTEX] of integer;
  end; (* FOREST *)



var
  InputGraph: GRAPH;              { the input graph itself        }
  BasisTree: FOREST;              { spanning forest of current basis }

{ **** end userGlob.i **** }
   
{ **** parityGlob.i **** }
   { This module contains those declarations which are independent of the 
   matroid elements and the implementation of required user-supplied 
   routines.
   
   The user must define the follwing types and constants

   ELEMENT - an ordinal type for indexing the matroid elements.

   NULLELEMENT - a constant of type ELEMENT used to initialize variables.
   NULLELEMENT should not correspond to an oridinal used 
   to indicate an actual matroid element.

   MAXRANK - a constant equal to the maximum rank of an input matroid.

   ELTYPE - a record defining the matroid element.

   EPTR -  a pointer to type ELTYPE

   }

{ ****************** Global variables for all matroids ********************}

var
   Parity: array [ELEMENT] of EPTR;  { array of edges in the graph }
   Mstar : array [1..MAXRANK] of ELEMENT; { current basis }
   BasicXform: array [1..MAXRANK] of ELEMENT;  { transforms in current basis }
   NumBasicXform: integer;   { number of transforms in the basis }
   NumEl: integer;           { number of matroid elements in problem }
   NumSingle : integer;      { number of singletons in Mstar }
   NumXform : integer;       { number of transforms in current iteration }
   InMS : array [ELEMENT] of boolean; { indicates if element is in Mstar }
   BasisSize: 0..MAXRANK;       { rank of matroid basis }


{ **** trace-module.t **** }
{ This module contains all routines which provide summary information about the
  calculations.
  The trace routine for procedure foo is named fooTrace.
}

var
  InBlossomTrace: boolean;  { indicator for output formatting }

    procedure writeElement(e : ELEMENT);
    var
      elementPtr : EPTR; 
    begin
      elementPtr := Parity[e];
      if e > NumEl + NumSingle then { is a transform }
        write(DELIM, e:MAXDIGIT, DELIM,
              ' !xf [', elementPtr^.el1:MAXDIGIT, ', ', elementPtr^.el2:MAXDIGIT, '] ')
      else
        write(DELIM, e:MAXDIGIT, DELIM,
             ' (', elementPtr^.end1:MAXDIGIT, ', ', elementPtr^.end2:MAXDIGIT, ') ');
    end; { writeElement }

    procedure augmentTrace;
    begin
      writeln('augment step-');
    end;

    procedure blossomTrace(bud,tip1,tip2:ELEMENT; trueTips: boolean);
    begin
      InBlossomTrace:= true;
      writeln('blossom step -');
      write('      tip1 = ');
      writeElement(tip1);
      write(', tip2 = ');
      writeElement(tip2);
      write(', bud = ');
      writeElement(bud);
      writeln;
      if trueTips then
        writeln('          true tips')
      else
        writeln('          not true tips');
    end; { blossomTrace }

    procedure checkAdjTrace(e, f: ELEMENT; equiv, adjacent: boolean);
    begin
      if adjacent then begin 
        if equiv then begin
          write('     ');
          writeElement(f);
          write(' equivalent to ');
          writeElement(e);
          writeln(', so do nothing')
        end { equivalent }
        else begin
          write('     ');
          writeElement(f);
          write(': ')
        end { not equivalent }
      end { adjacent }
    end; { checkAdjTrace }

    procedure compactSinglesTrace;
    var
      index: integer;
    begin
      InBlossomTrace:= false;  { initialize formatting boolean }
      writeln;
      writeln;
      writeln('*************  enter IncreaseMatching ***************');
      writeln;
      writeln(' there are now ', NumSingle:MAXDIGIT, ' singletons');
      writeln(' they are:');
      for index := NumEl + 1 to NumEl + NumSingle do begin
        writeElement(index); writeln
      end
    end; { compactSinglesTrace }

    procedure CreateTransformTrace(z, x, y, bud: ELEMENT);
    begin
      InBlossomTrace:= false;
      write('           create ');
      write(z:MAXDIGIT);
      write(' = T(');
      writeElement(x);
      write(', ');
      writeElement(y);
      write(', ');
      writeElement(bud);
      writeln(')');
      write('          ');   { format for label trace }
    end; { CreateTransformTrace }


    procedure degenerateBlossomTrace;
    begin
      writeln('degenerate blossom');
    end;


    procedure giveLabelTrace(f,back,reverse: ELEMENT; serial: integer);
    begin
      if InBlossomTrace then
        write('          ');
      writeln('label[',DELIM,f:MAXDIGIT,DELIM,']=(',DELIM,back:MAXDIGIT,DELIM,
                ',' ,DELIM,reverse:MAXDIGIT,DELIM, ')   s(',DELIM,f:MAXDIGIT,DELIM,
                ')=',serial:MAXDIGIT);
    end; { giveLabelTrace }

    procedure newBasisGraphTrace(e: ELEMENT; v,w: VERTEX);
    begin
    end;

    procedure readMatchTrace(initMatch: INDICATOR; num: integer);
    var
      arc: integer;
    begin
      writeln('Initial Matching List'); 
      for arc := 1 to num do
        if initMatch[arc] then begin
            writeElement(arc);
            writeln;
        end
    end;

    procedure scanTrace(e: ELEMENT);
    begin
      writeln;
      write('scan label on ');
      writeElement(e);
      writeln(' ; adjacent to--');
    end;

    procedure SwapTrace(e: ELEMENT; putIn: boolean);
    begin
      if putIn then begin
        write('    put element ');
        writeElement(e);
        writeln(' in basis')
      end
      else begin
        write('    removed element ');
        writeElement(e);
        writeln(' from basis')
      end
    end;

    procedure tryToGrowTrace(e, f, fbar: ELEMENT;
                             equiv, unlabeled, pending,
                             mateUnlabeled, degen: boolean);
    begin
      if unlabeled or pending then begin
        write('     ');
        writeElement(f);
        write(': ');
        if equiv then
          writeln(DELIM,f:MAXDIGIT,DELIM,' equivalent to ',DELIM,e:MAXDIGIT,DELIM,
                  ', so do nothing')
        else if degen then
          writeln(DELIM,f:MAXDIGIT,DELIM,
                  ' is a tip of a degenerate blossom, so do nothing.')
        else if pending then 
          writeln('s[',DELIM,f:MAXDIGIT,DELIM,']>s[',DELIM,e:MAXDIGIT,DELIM,
                  '] ,so do nothing for now')
        else if not mateUnlabeled then
          writeln(DELIM,fbar:MAXDIGIT,DELIM,
                  ' mate already labeled so do nothing');
        end; { if unlabeled or pending }
    end; { tryToGrowTrace }

{ **** end parityGlob.i **** }

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
      {D writeln(' clear adjacency list for vertex', i);}
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
   {D writeln(' -> AddEdgeGr with vertices', u : MAXDIGIT, v : MAXDIGIT); }
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

procedure ForAdjGr(g: GRAPH; u:VERTEX; procedure P( v:VERTEX));
  var
    ap: aptr;
  begin
    ap := g.adjacency[u];
    while ap <> nil do begin
      P(ap^.vnum);
      ap:= ap^.next;
    end; (* while *)
  end; (* For Adjacent in Graph *)

procedure ForVertex( g: GRAPH; procedure P(v: VERTEX));
  var
    v: VERTEX;
  begin
    {D writeln(' enter FOR VERTEX');}
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
      writeln(' entered PrintAdjList'); 
      for i:= 1 to g.numVertex do begin
	write('adjacency list for vertex ',i);
	ap:= g.adjacency[i];
	while ap <> nil do begin
	  write (ap^.vnum);
	  ap:= ap^.next;
	end; (* while *)
        writeln;
      end; (* for *)
      writeln(' exited PrintAdjList');
    end; (* PrintAdjList *)            

{ **** end graph.i ****}

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
	ForVertex(g:GRAPH, procedue P(v:VERTEX));
	  This procedure performs P on every vertex v in g.
	
	ForAdjGr(g:GRAPH; u:VERTEX, procedure P(v:VERTEX))
	  This procedure performs P for every vertex v adjacent to u in g.

     The following operations can be performed on a spanning tree:
       
       1. InitSpForest(g:GRAPH; t:FOREST, procedure P(u,v:VERTEX))
	   This procedure initializes t to be a spanning forest for g.
	   t is a "returned" parameter from InitSpForest, in that
	   t is not defined when InitSpForest is called.
	   The procedure P is performed for every tree edge u,v in the 
	   spanning forest.

       2. IsInCycle(v, w, x, y : VERTEX; t : FOREST): boolean;
	   true if tree edge v,w is in the fundamental cycle formed when
	   edge x,y is added to the spanning tree t.

	   ********** NOTE *******
	   IsInCycle does not check that v,w is an edge in the forest.
}

  {
    Performs a dfs of the graph, applying procedure P to each tree edge uv
  }
  procedure InitSpForest(g : GRAPH; var t : FOREST; procedure P(u, v : VERTEX));
  var
    visited : array [VERTEX] of boolean;   { indicator array }
    dfsn : integer;     { global to search for assigning PRE }

    function search(node : VERTEX): integer;
     { search is called recusivly to perform a depth first search.
     The input parameter is the current node in the search.
     search returns the highest pre-order number of a descendent
     of the input node. }
   
      procedure continueSearch(v: VERTEX);
        begin
          {D writeln(' enter CONTINUE SEARCH with node', v);}
          if not visited[v] then begin
            { do P to the edge node,v }
              P(node, v);
              t.high[node] := search(v);
           end; (* if *)
      end; (* continueSearch *)

    begin  (* search *)
      {D writeln (' entered search with node ', node);}
      visited[node] := true;
      dfsn:= dfsn + 1;
      t.pre[node] := dfsn;
      t.high[node] := dfsn;
      {D writeln(' pre-order number of node is ', dfsn);}
      ForAdjGr(g, node, continueSearch); {  search through adjacency list }
      search:= t.high[node];
      {D writeln(' HIGH set to ',t.high[node],' for node ',node);}
    end; (* Search *)

  procedure rootIfNotVisited(v: VERTEX);
    begin
      {D writeln(' entered ROOT IF NOT VISITED with vertex', v);}
      if not visited[v] then
	      t.high[v]:= search(v);
  end; (* rootIfNotVisited *)

  procedure initialVisited(v: VERTEX );
    begin
      visited[v]:= false;
  end;

  begin (* InitSpForest *)
    { initialize  }
    dfsn := 0;
    ForVertex(g, initialVisited);
     { end initialization }
    ForVertex(g, rootIfNotVisited);
  end; (* InitSpForest *)


function IsInCycle(v,w,x,y: VERTEX; t: FOREST): boolean;
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

{ ***** end spforest.i ****** }

 { **** queues.i **** }
 { This module implements the data type QUEUE. 
    The module can implement any number of QUEUE's , but all
    QUEUE's must contain the same type of entity.
    The entities to be placed on QUEUE's must be defined by the 
    user in a global type called QDATA.

    A copy of the entities passed to AddQ are stored on a QUEUE.
    Therefore, the actual entity need not be retained after it is
    placed on a QUEUE.

    The following operations are defined for a QUEUE:
      1. InitialQ ( var q:QUEUE ) 
	   Initializes the QUEUE  q to an empty state.
      2. MTQ (q:QUEUE): boolean
	   returns 'true' if q is empty, 'false' otherwise.
      3. DelQ (var q:QUEUE) :QDATA 
	   removes the first entity on the QUEUE q.

	   If DelQ is called when q is empty, the results will be 
	   unpredictable. 
	   Always use MTQ before DelQ.
	 If DelQ is called with an empty queue, a message is written to the 
	 Standard Output, and execution is halted.

      4. AddQ ( q:QUEUE, var item:QDATA)
	   Places the entity 'item' at the end of QUEUE q.
      5. FlushQ (q:QUEUE)
	   removes all entities from QUEUE q, and leaves q in the empty 
	   state.
      6. DoToQ( var q: QUEUE; procedure P(item: QDATA));
           DoToQ performs the procedure P to every item on the queue q.
	   The queue is not altered by DoToQ, unless P performs some operations 
	   on it.
				    }
type 
  linptr = ^linkedNode;
  linkedNode = record
		item: QDATA;  { QDATA is defined by user in an 
				external module       }
		next: linptr;
	       end;
  QUEUE = record
	    head: linptr;
	    tail: linptr;
	  end;

  procedure InitialQ (var q: QUEUE);
    begin
      q.head:= nil;
    end; (* Initial Q *)

  function MTQ(q:QUEUE): boolean;
    begin
      MTQ:= q.head = nil;
    end;

  procedure AddQ (var q: QUEUE; newthing: QDATA);
    var
      p: linptr;
    begin
      new(p);
      p^.item:= newthing;
      p^.next:= nil;
      if MTQ(q) then 
	q.head:= p
      else
	q.tail^.next:= p;
      q.tail:= p;
    end;

  function DelQ(var q:QUEUE): QDATA;
    var
      p: linptr;
    begin
      if MTQ(q) then begin
	writeln(' DelQ called with empty queue. Execution halted.');
	halt;
      end;
      DelQ:= q.head^.item;
      p:= q.head;
      q.head:= q.head^.next;
      dispose(p);
    end;

  procedure FlushQ (var q: QUEUE);
    var
      p: linptr;
    begin
      p:= q.head;
      while p <> nil do begin
	q.head:= p^.next;
	dispose(p);
	p:= q.head;
      end; (* while *)
    end; (* FlushQ *)


procedure DoToQ( var q: QUEUE; procedure P(item: QDATA));
  var
    link: linptr;
  begin
    link:= q.head;
    while link <> nil do begin
      P(link^.item);
      link:= link^.next;
    end; (* while *)
  end; (* Do To Q *)

{ **** end queues.i ****** }

{ **** equiv.i **** }
{ equiv.i -- implementation of MFSETs, using path compression and merge
	by rank (see AHU, chapter 5); note: this is not in "showcase"
	form, and probably won't be even in our final version: it is
	difficult to get around the assumption that elements are array
	indices. }

var
	Parent: array [ELEMENT] of ELEMENT;
		{ parent of an element in the tree representation of
		  an MFSET }
	Rank: array [ELEMENT] of 0..LOGMAXELEMENTS;
		{ length of the longest path in the tree ending at that
		  element }

procedure InitEquivalence (m: integer);
  { initialize a set of equivalence classes on m elements by putting
    each element into an equivalence class by itself }
  var e: ELEMENT;
  begin
    for e := 1 to m do begin
	Parent [e] := e;
	Rank [e] := 0 end
  end; (* Init Equivalence *)

function find (e: ELEMENT): ELEMENT;
  { return the root of the tree in which e is located, and do path
    compression along the path from e to the root;

    the path compression method used is called "halving" and is described
    in Tarjan and Van Leeuwen, "Worst case analysis of set union algorithms,"
    JACM, April, 1984 }
  begin
    while Parent [e] <> Parent [Parent [e]] do begin
	Parent [e] := Parent [Parent [e]];
	e := Parent [e] end;
    find := Parent [e]
  end; (* find *)

function AreEquivalent (e,f: ELEMENT): boolean;
  { true if e and f are in the same equivalence class }
  begin
    AreEquivalent := find (e) = find (f)
  end;

procedure Merge (e,f: ELEMENT);
  { make e and f equivalent (if they are not already), that is, merge the
    equivalence class containing e with that containing f;

    this is done by linking the roots of the two trees in such a way that
    the root with higher rank becomes the root of the new tree }
  var roote,rootf: ELEMENT;	{ roots of the respective trees }
  begin
    roote := find (e); rootf := find (f);
    if roote <> rootf then
	if Rank [roote] > Rank [rootf] then
		Parent [rootf] := roote
	else if Rank [roote] < Rank [rootf] then
		Parent [roote] := rootf
	else (* Rank [roote] = Rank [rootf] *) begin
		Parent [rootf] := roote;
		Rank [roote] := Rank [roote] + 1 end
  end; (* Merge *)

{ **** end, equiv.i **** }

{ **** depgraph.i **** }
{ This module implements the operations to be performed on the dependence
  graph of the current basis.
  All global variables used in this module are defined in either
  parityGlob.i or userGlob.i, except for BasisGraph.

  The following operations are provided for manipulating the 
  dependence graph:

      1. IsInMstar( e: ELEMENT): boolean
	  Returns true if e is in the current basis, false otherwise.
      2.  Mate(e: ELEMENT): ELEMENT
	  Returns the parity mate of e.
      3. ForAdjacent( e: ELEMENT, procedure P( f: ELEMENT))
	  Performs P for every element f adjacent to e in the dependance 
	    graph.
      4. GetInitialBasis
	  Constructs an initial basis of all singletons from the input graph.
      5. ForElement( procedure P(e: ELEMENT))
	  executes P for every element in the matroid.
      6. Swap(e: ELEMENT)
	  Swap modifies the global indicator array InMS to indicate a 
          change in the basis.
          The element e (and its mate if e is not a singleton ), are put into
          or removed from the basis, according to its current status. 
      7. Update
          Update calls the routines which update the dependence graph
	  and the basis Mstar. 
	  Update is called after all calls to Swap have been made.

  Routines which deal with transforms and singletons are in the modules 
  transforms.i and singletons.i, resp.
}

var
  BasisGraph: GRAPH;    { graph containing the edges of the current basis }

function IsInMstar(e: ELEMENT): boolean;
  begin
    IsInMstar:= InMS[e];
  end; (* IsInMstar *)

{  Include subsidiary modules }

{ **** singletons.i **** }
{ This module contains those routines which handle singletons.
  The routines are:

    1. IsSingleton(e : ELEMENT): boolean
	Returns true if e is a singleton.
    2. makeSingleton(v1, v2 : VERTEX)
	This routine is a support procedure for the routine GetInitialBasis.
	makeSingleton creates an entry in the Parity data structure for the
	edge (v1,v2) as a singleton.
    3. ForSingleton(procedure P(e: ELEMENT))
	Performs P to every singleton.
    4. compactSingles
	This routine is a support procedure for the routine Update.
	compactSingles removes from the Parity data structure those singletons
	which have been Swapped, and renumbers the remaining singletons.
}

function IsSingleton(e: ELEMENT): boolean;
  begin
    IsSingleton:= (e > NumEl) and (e <= NumEl+NumSingle )
  end; (* Is Singleton *)
   

  procedure makeSingleton(v1, v2 : VERTEX);
  { this procedure adds the edge v1, v2 to Mstar }
    var
      e : EPTR;       { points to an edge }
      pos : ELEMENT;  { array index }
  begin
    new(e);
    e^.end1 := v1;
    e^.end2 := v2;
    NumSingle := NumSingle + 1;
    pos := NumEl + NumSingle;

    Parity[pos] := e;
    Mstar[NumSingle] := pos;
    BasisSize := BasisSize + 1;
    InMS[pos] := true;
    write('Created singleton ');
    writeElement(pos);
    writeln;
  end; (* makeSingleton *)
  

procedure ForSingleton( procedure P(e:ELEMENT));
  var
    i : ELEMENT;
  begin
    for i := NumEl + 1 to NumEl + NumSingle do P(i);
  end;  (* ForSingleton  *)

  
  procedure compactSingles;
  {
  This procedure renumbers the singletons in the new basis
  so that they form a contiguous sequence.
  
  NumSingle is reset by this procedure.

  The procedure uses two pointers:
  - 'last' is initially set to the index in Parity
  of the highest numbered singleton in the old basis.
  - 'gap' is initially set to the lowest numbered singleton.
  In the main loop, last is initially moved to point to the 
  highest numbered singleton still in the basis.
  If there is no such singleton, then last will be set to a value less 
  than that of gap. This is the only case in which last will be less than gap.

  In the event that there are singletons remaining in the basis,
  the procedure then increments gap to point to a singleton not in the 
  basis.

  If there is no such singleton, gap will end up pointing to last.
  If there is such a singleton, the singleton pointed to by last
  is moved to position 'gap' to make the sequence more contiguous.
  Last is then decremented by one, and the loop repeats.
  When last<=gap, all singletons in the basis have contiguous numbers.
  At the end of the repeat loop, last and gap both point
  to the last singleton in the new basis, provided there is one.
  }

  var 
    gap, last : integer;

  begin (* compact singles *)
    last := NumEl + NumSingle;    { position of last singleton  }
    gap := NumEl + 1;             { position of first singleton }
    { main loop }
    repeat
      while not IsInMstar(last) and (last >= gap) do begin
        last := last - 1
      end;
      { last now points to highest numbered singleton still in Mstar }
      while IsInMstar(gap) and (gap < last) do begin
        gap:= gap + 1;
      end;
      { gap now points to position of a singleton removed from Mstar 
	      or to last if compaction is completed }

      if (last > gap) then begin
        { not at end of compaction, so swap singleton in last position
          with the one in gap that is no longer in Mstar }
        Parity[gap]:= Parity[last];
        InMS[gap]:= true;
        InMS[last]:= false;
        last:= last - 1;
      end; (* if *)
    until last <= gap;
    { reset number of singletons  }
    if (last < gap) then 
       NumSingle := 0
    else
      NumSingle := last - NumEl;
      compactSinglesTrace; 
  end; (* compact singles *)

{ ***** end, singletons.i ****** }

{ **** transforms.i **** }
{ This module contains those routines which deal with transforms.
  The routines in this module are:

      1. IsTransform( e: ELEMENT): ELEMENT
	  Returns true if e is a transform, false otherwise.
      2. Equivalent(x,y: ELEMENT): boolean
	  Returns true if the elements x and y have been made equivalent.
	  x and y may be transforms, regular matroid elements or singletons.
      3. MakeEquivalent(x,y: ELEMENT)
	  Merges the equivalence classes containing x and y.
	  x and y may be transforms or matroid elements, but not singletons.
      4. IsAdjacent( e,f: ELEMENT): boolean
	  Returns true if e is adjacent to f in the dependance graph of
	    the current basis.
      5. CreateTransform( x,y,b: ELEMENT): ELEMENT
	  Creates the transform for the blossom with bud b and tips x and y.
	  The transform is stored in the Parity data stucture, and
	  is included in the basis if both x and y are in the basis.
	  The returned value is the number of the new transform.
      6. FirstTip(e: ELEMENT): ELEMENT
	  Returns the 'first' tip of a transform, i.e. that tip for 
	  which the transform label gives the path through the blossom.
      7. SecondTip(e: ELEMENT): ELEMENT
	  Returns the 'second' tip of a transform. For this tip the path
	  through the blossom is given by the label (y,x) where (x,y) is 
	  the label on the transform.
                                                                     
								     }

function IsTransform( e: ELEMENT): boolean;
  begin
    IsTransform:= e > NumEl + NumSingle;
  end;
  
function Equivalent(x,y: ELEMENT): boolean;
  { This function returns true if x and y are in the same equivalence class }
  var
    a,b: ELEMENT;
  begin
    if IsSingleton(x) or IsSingleton(y) then
      Equivalent:= false
    else begin
      if IsTransform(x) then
	      a:= Parity[x]^.el2
      else
	      a:= x;
      if IsTransform(y) then 
	      b:= Parity[y]^.el2
      else
	      b:= y;
      Equivalent:= AreEquivalent(a,b);
    end; (* else, i.e., neither element is a singleton *)
  end; (* Equivalent *)


procedure MakeEquivalent( x,y: ELEMENT);
  var
    a,b: ELEMENT;
  begin
    if IsTransform(x) then
      a:= Parity[x]^.el2
    else 
      a:= x;
    
    if IsTransform(y) then
      b:= Parity[y]^.el2
    else
      b:= y;
    Merge(a,b);
  end; (* Make Equivalent *)
    

function IsAdjacent(e,f: ELEMENT): boolean;

  function isAdjElEl(e,f: ELEMENT): boolean;
    var
      inel,outel: ELEMENT;  { element in and not in basis, resp }
    begin
      if IsInMstar(e) then begin
	      inel:= e;
	      outel:= f;
      end
      else begin
	      inel:= f;
	      outel:= e;
      end; (* if *)
      isAdjElEl:= IsInCycle(Parity[inel]^.end1, Parity[inel]^.end2,
        		     Parity[outel]^.end1, Parity[outel]^.end2,
        		     BasisTree);
    end;

  function isAdjXEl( x,e: ELEMENT): boolean;
    begin
      isAdjXEl:= isAdjElEl(Parity[x]^.el1, e) <> isAdjElEl(Parity[x]^.el2, e);
    end;

  function isAdjXX( x,y: ELEMENT): boolean;
    begin
      isAdjXX:= isAdjXEl(x, Parity[y]^.el1) <> isAdjXEl(x, Parity[y]^.el2);
    end;

  begin  (* IsAdjacent *)
    if IsInMstar(e) = IsInMstar(f) then
      IsAdjacent:= false
    else if IsTransform(e) then 
      if IsTransform(f) then 
	      IsAdjacent:= isAdjXX(e,f)
	    else
	      IsAdjacent:= isAdjXEl(e,f)
    else if IsTransform(f) then
	      IsAdjacent:= isAdjXEl(f,e)
	  else
	    IsAdjacent:= isAdjElEl(e,f);
  end; (* IsAdjacent *)



function CreateTransform(x,y,b: ELEMENT): ELEMENT;
  var p: EPTR;
      xnum: integer;
  begin
    new(p);
    p^.el1:= x;
    p^.el2:= y;
    NumXform:= NumXform + 1;
    xnum:= NumEl+ NumSingle + NumXform;
    Parity[xnum]:= p;
    if IsInMstar(x) and IsInMstar(y) then begin
      NumBasicXform:= NumBasicXform + 1;
      BasicXform[NumBasicXform]:= xnum;
      InMS[xnum]:= true;
     end
    else
      InMS[xnum]:= false;
    CreateTransform:= xnum;
    CreateTransformTrace(xnum, x, y, b);  
  end; (* Create Transform *)


function FirstTip(e: ELEMENT): ELEMENT;
  begin
    FirstTip:= Parity[e]^.el1;
  end;

function SecondTip(e: ELEMENT): ELEMENT;
  begin
    SecondTip:= Parity[e]^.el2;
  end;

function Mate(e: ELEMENT): ELEMENT;
  { this function returns the mate of the element e }
  begin
    if IsSingleton(e) or IsTransform(e) then
      Mate:= NULLELEMENT
    else
      if (e mod 2) = 0 then
	      Mate:= e - 1
      else
	      Mate:= e + 1;
  end;

procedure ForAdjacent(e: ELEMENT; procedure P(o:ELEMENT));
  var 
    f: ELEMENT;    { name of an element adjacent to e }
    i: integer;    { loop indexing }
  begin
   if IsInMstar(e) then
     for f:= 1 to NumEl + NumSingle + NumXform do
	  if IsAdjacent(e,f) then
	    P(f)
	  else
   else begin
     for i:= 1 to BasisSize do
       if IsAdjacent(e,Mstar[i]) then
	 P(Mstar[i]);
{ look at transforms in Mstar  }
     for i:= 1 to NumBasicXform do
       if IsAdjacent(e, BasicXform[i]) then
	 P(BasicXform[i]);
   end; (* if *)
  end; (* For Adjacent  *)

procedure GetInitialBasis;
  { this routine constructs an initial basis of singletons from the 
    edges in a depth first search tree of the input graph.  }

var
   j: integer;  { counter }

begin (* GetInitialBasis *)
   { initialize }
  for j:= 1 to NumEl do
    InMS[j]:= false;
  BasisSize:= 0;
  NumXform:= 0;
   { end initialize }
  InitSpForest(InputGraph, BasisTree, makeSingleton);
end; (* GetInitialBasis *)



procedure ForElement(procedure P(e: ELEMENT));
  var
    i: ELEMENT;
  begin
    for i:= 1 to NumEl do
      P(i);
  end;

procedure updateDepGraph;
  procedure NullProc(u,v:VERTEX);
    begin
    end;

  begin
    InitSpForest(BasisGraph, BasisTree, NullProc);
  end;


   procedure PrintEl(j: ELEMENT);
      begin
         write(' +');
         writeElement(j);
      end;  

    procedure PrintDepGraph;
      var
	i: ELEMENT;
      begin
	writeln('> Adjacency lists for dependency graph');
	for i:= 1 to NumEl + NumSingle + NumXform do
	  if InMS[i] then begin
             writeElement(i);
             write(':');
             ForAdjacent(i, printEl);
             writeln;
	  end;
         writeln('< end, adjacency lists');
         writeln;
      end; (* Print Dep Graph *)  


procedure Swap(e: ELEMENT);
  begin
    InMS[e]:= not InMS[e];
    if not IsSingleton(e) then  { e has a mate }
       begin
	  SwapTrace(e, InMS[e]);  SwapTrace(Mate(e), InMS[e]); 
          InMS[Mate(e)]:= InMS[e];
       end
    else
       SwapTrace(e,InMS[e]);  
  end;  (* SWAP *)

procedure Update;
  
  procedure chMstar;
    { This procedure updates the array Mstar to reflect the changes in 
       the basis }

    var
      i, pos: integer;
    begin
      { set pos to the first non-singleton position in Mstar }
      pos:= NumSingle + 1;
      for i:= 1 to NumEl do
	if InMS[i] then begin
	  Mstar[pos]:= i;
	  pos:= pos + 1;
	end; (* if *)
    end; (* Ch Mstar *)


  procedure newBasisGraph;
    { this procedure sets BasisGraph to be the graph of basic edges }
  var
    i: integer;
  begin
    EraseGr(BasisGraph);
    for i:= 1 to BasisSize do
	  begin
      newBasisGraphTrace(Mstar[i],
			                  Parity[Mstar[i]]^.end1, Parity[Mstar[i]]^.end2); 
	    AddEdgeGr(BasisGraph, Parity[Mstar[i]]^.end1, Parity[Mstar[i]]^.end2);
	 end; (* for *) 
  end; (* new basis graph *)

  begin (* Update *)
    compactSingles;
    chMstar;
    newBasisGraph;
    updateDepGraph;
    NumXform:= 0;
  end; (* Update *)

{ ***** end, depgraph.i ******** }

{ **** input-output.i **** }
{ this module contains the initialization routine, and the initial
  basis routine when the input matroid is a graph  } 


var
    NumArcs: integer;               { number of arcs in input graph }
    NumNode: integer;               { number of nodes in input graph }

procedure Initialize;
  { This routine performs the following functions
      1. Reads in number of nodes in a graph.
         The number of nodes appears on a line by itself.
      2. Reads in edges of the graph.
	 The edges are specified as pairs of vertices. vertices are integers
	  in the range 1..MAXV.

	 Each pair of vertices defining an edge appear on a line
	 by themselves. The input routine indexes the edges with sequential
	 integers, beginning with 1, according to their position in the input
	 list, up to a maximum value of MAXE.

         At the end of the edge list, the pair  '0 0' must appear on a line
	 by itself.

         It is assummed that the edges are input with parity mates
	 occurring sequentially.

	 There must be an even number of edges input.
      
	 The input is stored in the global variable InputData, a GRAPH.

      3. Edges are stored in the 'Parity' data structure.   

      4. Reads in an initial matching. 
	 The initial matching is input after the delimiter line ' 0 0 '.
	 These edges are input by their edge number, (see item 2 above).

	 The initial matching list is terminated by a 0 on a line by itself.

      5. The routine ends with an error if either
	  (a) The set of edges for the intial matching does not define a 
	       matching, or
	  (b) The set of edges for the intital matching contains an edge, 
	       but not the parity mate of that edge.
                                                                      }

  var
    initMatch: INDICATOR;  { indicator array of elements 
					     in the intial matching      }
  
  procedure readArcs; 
    { This routine reads in the number of nodes in the input graph, and
      the edges in the input graph.
      These items are stored in the appropriate data structures.  }

  var
    newedge: EPTR;      { pointer to edge data type }
    v1,v2: VERTEX;      { endpoints of an edge } 
    a1,a2: integer;     { used to read in vertex pairs.
			     Separate variables are required for this purpose
			     as the type VERTEX does not include 0, the end 
			     of list delimiter value }
    even: boolean;      { tests number of edges input }
  begin
    readln(NumNode);
    InitGr(InputGraph, NumNode);
    { read in edges }
    NumArcs:= 0;       { initialize number of edges }
    even := true;
    readln(a1,a2);
    while ( a1 <> 0 ) and ( a2<> 0 ) do begin
	    v1 := a1;
	    v2 := a2;
      NumArcs:= NumArcs + 1;
      even:= not even;
      {E writeln(' edge number ',NumArcs,' has endpoints ',v1,v2); }
      { check edge }
      if NumArcs > MAXE then begin
	      writeln(' maximum number of edges ',MAXE,' exceeded');
	      halt;
	    end; (* if max edges exceeded *)
	    if ( v1 < 1 ) or ( v1 > NumNode ) or ( v2 < 1 ) or ( v2 > NumNode ) then begin
	      writeln(' node numbers must be in the range 1..', NumNode);
	      halt;
	    end; (* if node number out of range *)
      { end checks }

      { store edge }
      new(newedge);
      newedge^.end1 := v1;
      newedge^.end2 := v2;
      Parity[NumArcs] := newedge;

      { update adjacency list }
      AddEdgeGr(InputGraph,v1,v2);
      readln(a1,a2);
    end; (* while a1<>0 and a2<>0 *)
    if not even then begin
      writeln(' number of edges in input graph must be even');
      halt;
    end; { odd number of edges }
    { set number of elements }
    NumEl:= NumArcs;
  end; (* read Arcs *)

  procedure readMatch;
    { This procedure reads in the initial matching. }

  var
    arc: ELEMENT;  { arc is an edge in the intial matching }
    
    procedure initInitMatch;
    var
	    i: integer;
    begin
	    for i := 1 to NumArcs do
	      initMatch[i]:= false;
    end; { initInitMatch - simply sets all edges to be not in current matching }

  begin (* read Match *)
    initInitMatch;
    readln(arc);  { first arc/element }
    while arc <> 0 do begin
	    { check edge number }
 	    if ( arc < 1 ) or ( arc > NumArcs ) then begin
 	      writeln( arc, ' is not a valid edge number');
	      writeln(' procedure aborted');
	      writeln(' check initial matching list');
	      halt;
 	    end; (* if edge number is not valid *)
	    if initMatch[arc] then
 	      writeln('Warning: ', arc,' is input for intial matching more than once');
 	    initMatch[arc]:= true;
	    readln(arc);
    end; (* while there are more initial matching edges *)
    { check that every edge in the intial matching has its mate in the
	    initial matching  }
    arc := 1;
    while arc < NumArcs do begin
	    if initMatch[arc] <> initMatch[arc+1] then begin
	      writeln(' only one of the pair ', arc, arc + 1,
		            ' is in the initial matching');
	      writeln(' execution halts');
	      halt;
	    end; (* if one element of a pair is in and the other is out of the initial matching *)
	    arc:= arc + 2;
    end; (* while *)
    readMatchTrace(initMatch, NumArcs); 
  end;  (* read Match *)

  procedure checkMatch; 
    { This routine verifies that the arcs input for the initial matching
      are indeed a matching.
      The arcs input are swapped into the basis.        }
  var
     i: integer;
     v, w: VERTEX;
  begin
    for i := 1 to NumArcs do 
      if initMatch[i] then begin
        v:= Parity[i]^.end1;
        w:= Parity[i]^.end2;
        if AreEquivalent(v,w) then begin
          writeln('edge ',i,' forms a cycle with edges previously',
                  ' selected for the initial matching');
          writeln(' execution halts');
          halt;
        end; (* if two edges of a pair form a cycle with previous matching elements *)
        Merge(v, w);
        { execute Swap for one of the parity mates }
        if i mod 2 = 0 then 
          Swap(i);
      end; (* if initMatch *)
  end; (* check Match *)


  procedure removeWhenRedundant(e: ELEMENT);
    { This procedure removes the singleton e from the basis if its
      ends are already in the basic spanning tree. }
  var
     v,w: VERTEX;
  begin
     v := Parity[e]^.end1;
     w := Parity[e]^.end2;
     if AreEquivalent(v,w) then
        Swap(e)
     else
        Merge(v,w);
  end; (* removeWhenRedundant *)

begin (* Initialize *)
   readArcs;
   GetInitialBasis;
   InitEquivalence(NumNode);
   readMatch;
   checkMatch;
   ForSingleton(removeWhenRedundant);
   InitGr(BasisGraph, NumNode);
   Update;
end; (* initialize *)

var
   Maximal: boolean;

function IncreaseMatching :boolean;
{ This function implements the main loop of the parity matching 
algorithm.
The current basis is stored in the global variable Mstar. 
IncreaseMatching returns true if there is a basis with a matching
of larger cardinal than Mstar. Upon return from IncreaseMatching,
Mstar is set to the new (augmented) basis, or the old basis if 
there is not a better matching. }

const
   NOLABEL = 0;     { serial number assigned to unlabeled elements }
type
   dualLabel = record
                  back: ELEMENT;
                  reverz: ELEMENT;
               end;
   
var
   e: ELEMENT;     { element on 'to be scanned' queue }
   SerialNum: integer;             { keeps track of last assigned serial #}
   Serial: array [ELEMENT] of integer; { serial number of elements }
   ToBeScannedQ,             { queue of unscanned, labeled elements}
   BasicScannedQ,            { queue of scanned elements in basis }
   NonBasicScannedQ: QUEUE;  { queue of scanned elements not in basis }
   Degenerate: array [ELEMENT] of boolean; { indicates if an element
                                           is in a degenerate blossom }
   SearchLabel: array [ELEMENT] of dualLabel; 
   augmented: boolean;   { set to true when an augmentation is done }
   OnPath: array [ELEMENT] of ELEMENT; { used by closest common ancestor
                                              search of routine BlossomAugment }
          
   procedure giveLabel(f, bac, rev: ELEMENT);
   { This routine assigns the label (bac,rev) to f, assigns f a 
   serial number, and places f on the 'to be scanned' queue }
   begin
      SearchLabel[f].back := bac;
      SearchLabel[f].reverz := rev;
      SerialNum := SerialNum + 1;
      Serial[f] := SerialNum;
      giveLabelTrace(f,bac,rev,SerialNum);
      AddQ(ToBeScannedQ, f);
   end;


   procedure initVars;
   { This procedure initializes all variables prior to searching 
   for a new matching  }

      procedure labelSingleton(e: ELEMENT);
      begin
        giveLabel(e, NULLELEMENT, NULLELEMENT);
      end;
   

      procedure unlabeled(e: ELEMENT);
      begin
         Serial[e]:= NOLABEL;
      end;
   
      procedure mergeMates(e: ELEMENT);
      begin
         MakeEquivalent(e, Mate(e));
      end;

      procedure notDegenerate(e: ELEMENT);
      begin
         Degenerate[e]:= false;
      end;

      procedure notOnPath(e: ELEMENT);
      begin
         OnPath[e]:= NULLELEMENT;
      end;

   begin (* initVar *)
      InitialQ(ToBeScannedQ);
      InitialQ(BasicScannedQ);
      InitialQ(NonBasicScannedQ);
      SerialNum:= 0;
      ForSingleton(labelSingleton);
      ForElement(unlabeled);
      Serial[NULLELEMENT]:= NOLABEL;
      ForElement(notDegenerate);
      ForSingleton(notOnPath);
      ForElement(notOnPath);
      InitEquivalence(NumEl);
      ForElement(mergeMates);
      NumBasicXform:= 0;
      augmented:= false;
   end;

   procedure scan(e: ELEMENT);
   { This procedure scans an element or transform.
   First the appropriate queue of scanned elements
   is processed, and new blossoms are
   formed or the matching is augmented if this is possible.

   Next, elements not already labeled which are adjacent to 
   e are scanned. New labels are assigned where appropriate. }
   
   

{ **** blossom-augment.i **** }
{ This module contains the routine blossomAugment called from the routine
  scan. }


procedure blossomAugment(e,f:ELEMENT);
  { This procedure examines the paths from e and f back to their
	roots. If the paths join, then a blossom is formed.
	If the paths do not join, an augmentation is called for. }
  var
	  bud: ELEMENT;  { the first element on both paths which is followed by its mate }
	  t1,t2: ELEMENT; { the predecessors of bud on the path back from e and f, respectivly }
      
  procedure tracePath(fromHere, toThere: ELEMENT; procedure P(e: ELEMENT));
	  { tracePath calls itself recursivly to trace the path from
	    node fromHere to node toThere.
	    procedure P is performed for each parity pair on the path }
	var
	  fH: ELEMENT; { equal to fromHere when fromHere is not a transform,
			             equal to a tip of fromHere when fromHere is a transform }
	begin  (* tracePath *)
	  if fromHere <> toThere then begin
	    if IsTransform(fromHere) then 
	      fH:= Parity[fromHere]^.el1
	    else
	      fH:= fromHere;
	    P(fH);
	    { continue finding path }
	    if SearchLabel[fromHere].reverz <> NULLELEMENT then 
	      tracePath(SearchLabel[fromHere].reverz, Mate(fH), P);
	    tracePath(SearchLabel[fromHere].back, toThere, P);
	  end; (* if fromHere not same as toThere *)
	end; (* tracePath *)

  procedure quickTrace( fromHere, toThere: ELEMENT; procedure P(e:ELEMENT));
	  { this procedure traces the path from fromHere to toThere, 
	    ignoring reverse pointers 
	     procedure P is performed for every parity pair encountered on the
	     quick trace path }
	
	begin  (* quickTrace *)
	  if fromHere <> toThere then begin
	    P(fromHere);
	    quickTrace(SearchLabel[fromHere].back, toThere, P);
	  end; (* if *)
	end; (* quickTrace *)

  procedure blossom(e, f, bud, tip1, tip2 : ELEMENT);
	  { This procedure forms the blossom which includes arc e,f.
	    bud is the bud of the blossom.
	    tip1, and tip2 are the predecessors of bud on the path back from
	    e and f, respectivly. tip1 and tip2 may be tips 
	    of the new blossom }
	  var
	    ePathPtr, fPathPtr: ELEMENT; { markers for tracing path back from
					 e and f, resp. }
	    x: ELEMENT;           { number of new transform }
	    makeXform: boolean;   { true if new transform should be formed }
	    labelTips: boolean;   { false if tip1 and tip2 are true tips }
	
	  function isTrueTips(h,g: ELEMENT):boolean;
	    { determines if h and g are the true tips of the new blossom.
	      It is assummed that h and g are the predecessors of the bud. }
	  begin
	    isTrueTips:= (Serial[h] = NOLABEL) and (Serial[g] = NOLABEL);
	  end;

	  function pruneList( pathPtr: ELEMENT): ELEMENT;
	  { traces path back from pathPtr until an element is reached
	    whose mate needs a label, or the bud is reached }
	    var
	      top: ELEMENT;
	  begin
	    top:= pathPtr;
	    while ( IsTransform(top) or (Serial[Mate(top)] <> NOLABEL)) 
	       and (top <> bud) do
	      top:= SearchLabel[top].back;
	    pruneList:= top;
	  end;  (* prune List  *)
	
	begin (* blossom *)
	  { initializations }
	  { determine if t1 and t2 are true tips }
	  labelTips:= not isTrueTips(tip1, tip2);
	  makeXform:= not (labelTips or Equivalent(tip1, tip2));
	  ePathPtr:= e;
	  fPathPtr:= f;
	  MakeEquivalent(e, f);
	  { end initializations }
    blossomTrace(bud, tip1, tip2, not labelTips);   

	  { trace paths back from e and f and assign lablels }
	  { set PathPtr's to point to first element on each path
	    whose mate needs a label  }
	  ePathPtr:= pruneList(ePathPtr);
	  fPathPtr:= pruneList(fPathPtr);

	  repeat
	    { trace 'e' path }
	    while (Serial[ePathPtr] > Serial[fPathPtr]) and (ePathPtr <> bud) do begin
	      MakeEquivalent(e, ePathPtr);
	      if (Mate(ePathPtr) <> tip1) or labelTips then
		      giveLabel(Mate(ePathPtr), f, e);
	      ePathPtr:= pruneList(SearchLabel[ePathPtr].back);
	    end; (* while *)
	    { trace f path  }
	    while (Serial[fPathPtr] > Serial[ePathPtr]) and (fPathPtr <> bud) do begin
	      MakeEquivalent(f,fPathPtr);
	      if (Mate(fPathPtr) <> tip2) or labelTips then
		      giveLabel(Mate(fPathPtr), e, f);
	      fPathPtr:= pruneList(SearchLabel[fPathPtr].back);
	    end; (* while *)
    until (ePathPtr = bud) and (fPathPtr = bud);

	  if makeXform then begin
	    x:= CreateTransform(tip1, tip2, bud);
	    giveLabel(x, f, e);
	    { initialize OnPath for new transform }
	    OnPath[x]:= NULLELEMENT;  
	  end; (* make Xform *)
	end; (* blossom  *) 
      
  procedure augment(e,f: ELEMENT);
	{ this procedure traces the augmenting path which 
	  includes the arc e,f  }
	begin
	  augmentTrace;           
	  tracePath(e, NULLELEMENT, Swap);
	  tracePath(f, NULLELEMENT, Swap);
	  augmented:= true;
	end; (* augment *)

  function closestCommonAncestor(e, f: ELEMENT): ELEMENT;
	  { This function finds and returns the first node on the
	    paths back from e and f which is followed by its mate.
	    An important side effect is the setting of t1 and t2,
	    which are the predecessors on each path of the 
	    node at which the paths join.
	    The function proceeds in two passes.
	    In the first pass, the path from e to a root is determined.
	    Each node in the path which is follwed by its mate has its 
	    predecessor stored in the array OnPath.
	    In the second pass, the path back from f is traced. Each node
	    on this path which is followed by its mate is checked
      against the OnPath array to see if it was also on the path
	    back from e. The sceond pass maintains the predecessor 
	    of the node being examined.   }
    var
	    cca: ELEMENT;  { estimate of join node }
	    previous: ELEMENT; { previous element visited }

    procedure mark(e: ELEMENT);
	    begin
	      OnPath[e]:= previous;
	      if IsTransform(e) then 
	        previous:= Mate(SecondTip(e))  
			    { will pick up trace from back label}
	      else
	        previous:= Mate(e);
	  end; { mark }

    procedure comparePaths(e: ELEMENT);
	    begin
	      if cca = NULLELEMENT then
	        if OnPath[e] <> NULLELEMENT then begin
	          cca:= e;
	          t1:= OnPath[e];
	        end (* if *)
	      else if IsTransform(e) then 
	        t2:= Mate(SecondTip(e))
	      else
	        t2:= Mate(e);
	  end; (* compare Path *)
	      
    procedure eraseMarks( e: ELEMENT);
	    begin
	      OnPath[e]:= NULLELEMENT;
	    end;

  begin (* closest Common Ancestor *)
  	previous:= f;      { initialize }
	  { first pass }
	  quickTrace(e, NULLELEMENT, mark);
	  { second pass }
	  cca:= NULLELEMENT;
	  quickTrace(f, NULLELEMENT, comparePaths);
	  closestCommonAncestor:= cca;

	  if cca <> NULLELEMENT then
	    { blossom found, clean up OnPath for next time }
	    quickTrace(e, NULLELEMENT, eraseMarks);
  end; (* closest Common Ancestor *)

begin (* blossom Augment *)
  if not Equivalent(e, f) then begin
	  bud:= closestCommonAncestor(e, f);
	  if bud = NULLELEMENT then
	    augment(e,f)
	  else
	    blossom(e,f,bud, t1,t2);
  end; (* if e and f are not equivalent *)
end; (* blossom augment *)

  procedure checkAdj(f: ELEMENT);
    { This procedure checks the conditions for an arc
      between two labeled elements to be 'scan-able', 
      and calls BlossomAugment if it is.    }
    begin
      if not augmented then begin
        checkAdjTrace(e, f, Equivalent(e,f), IsAdjacent(e,f)); 
        if IsAdjacent(e,f) and not Equivalent(e,f) then
          blossomAugment(e, f);
      end; 
  end; (* check Adj *)

  procedure tryToGrow(f: ELEMENT);
    { This procedure examines an element f adjacent to e, and
      assigns it a label if appropriate.  }
    var
      x: ELEMENT;
    begin
      tryToGrowTrace(e, f, Mate(f), Equivalent(e,f), Serial[f]=NOLABEL,
                   Serial[f]>Serial[e], Serial[Mate(f)]= NOLABEL,
                   Degenerate[f]); 
      if not Equivalent(e,f) and
          (Serial[f] = NOLABEL) and
          (Serial[Mate(f)] = NOLABEL) and
          not Degenerate[f] then begin
        if IsAdjacent(e,Mate(f)) then begin
          degenerateBlossomTrace;  
          x:= CreateTransform(f,Mate(f),e);
          Degenerate[f]:= true;
          Degenerate[Mate(f)]:= true;
          giveLabel(x,e,NULLELEMENT);
          OnPath[x]:= NULLELEMENT;
        end  (* if IsAdj... *)
        else
          giveLabel( Mate(f), e, NULLELEMENT);
      end (* if not Equivalent...  *)
  end; (* tryToGrow *)

  begin (* scan *)
    scanTrace(e);   
    if IsInMstar(e) then begin
      DoToQ(NonBasicScannedQ, checkAdj);
      AddQ(BasicScannedQ, e);
    end
    else begin
      DoToQ(BasicScannedQ, checkAdj);
      AddQ(NonBasicScannedQ, e);
    end;  (* if IsInMstar(e)  *)
    if not augmented then
      ForAdjacent(e, tryToGrow);
  end; (* scan *)

begin (* IncreaseMatching *)
  initVars;
  while (not MTQ(ToBeScannedQ)) and (not augmented) do begin
    e:= DelQ(ToBeScannedQ);
    scan(e);
  end; (* while*)
  IncreaseMatching:= augmented;
  { recover space from queues }
  FlushQ(ToBeScannedQ);
  FlushQ(BasicScannedQ);
  FlushQ(NonBasicScannedQ);
end; (* IncreaseMatching *)

procedure Solution;   
{ This procedure print the solution }
  var i:ELEMENT;

  begin
     writeln;
     writeln;
    for i:= 1 to NumEl do
      if InMS[i] then
         writeln(' edge ', i : MAXDIGIT,' in optimal solution  (',
                 Parity[i]^.end1 : MAXDIGIT, ', ', Parity[i]^.end2 : MAXDIGIT, ')');
end;  (* solution *)    

begin { main program }
   Initialize;
   {D PrintAdjList(InputGraph);}
   PrintDepGraph;
   { begin main loop }
   Maximal:= not IncreaseMatching;
   while not Maximal do begin
      Update;
      PrintDepGraph;
      Maximal:= not IncreaseMatching;
   end; (* while *)
   Solution;
end.
