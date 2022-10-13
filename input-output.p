
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
    {E writeln(' number of vertices is ',NumNode); }
      InitGr(InputGraph, NumNode);
    { read in edges }

      NumArcs:= 0;       { initialize number of edges }
      even := true;
      readln(a1,a2);
      while (a1<> 0) and (a2<> 0) do begin
	v1:= a1;
	v2:= a2;
        NumArcs:= NumArcs+1;
        even:= not even;
      {E writeln(' edge number ',NumArcs,' has endpoints ',v1,v2); }
      { check edge }
        if NumArcs > MAXE then begin
	  writeln(' maximum number of edges ',MAXE,' exceeded');
	  halt;
	end; (* if *)
	if (v1<1) or (v1>NumNode) or (v2<1) or (v2>NumNode) then begin
	  writeln(' node numbers must be in the range 1..',NumNode);
	  halt;
	end; (* if *)
      { end checks }
      { store edge }

        new (newedge,normal);
        newedge^.end1:= v1;
        newedge^.end2:= v2;
        Parity[NumArcs]:= newedge;

      { update adjacency list }
        AddEdgeGr(InputGraph,v1,v2);
        readln(a1,a2);
      end; (* while a1<>0 and a2<>0 *)
      if not even then begin
        writeln(' number of edges in input graph must be even');
        halt;
      end;
    { set NumEl }
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
	for i:=1 to NumArcs do
	  initMatch[i]:= false;
      end;

    begin (* read Match *)
      initInitMatch;
      readln(arc);  { first value }
      while arc <> 0 do begin
	{ check edge number }
	if (arc < 1) or (arc > NumArcs) then begin
	  writeln( arc, ' is not a valid edge number');
	  writeln(' procedure aborted');
	  writeln(' check initial matching list');
	  halt;
	end; (* if *)
	if initMatch[arc] then
	  writeln(arc,' is input for intial matching more than once');
	initMatch[arc]:= true;
	readln(arc);
      end; (* while *)
      { check that every edge in the intial matching has its mate in the
	 initial matching  }
      arc:= 1;
      while arc < NumArcs do begin
	if initMatch[arc] <> initMatch[arc+1] then begin
	  writeln(' only one of the pair ',arc,arc+1,
		  ' is in the initial matching');
	  writeln(' execution halts');
	  halt;
	end; (* if *)
	arc:= arc+2;
      end; (* while *)
       readMatchTrace(initMatch,NumArcs); 
    end; (* read Match *)


  procedure checkMatch; 
    { This routine verifies that the arcs input for the initial matching
      are indeed a matching.
      The arcs input are swapped into the basis.        }
    var
      i: integer;
      v,w: VERTEX;
    begin
      for i:=1 to NumArcs do 
        if initMatch[i] then begin
          v:= Parity[i]^.end1;
          w:= Parity[i]^.end2;
          if AreEquivalent(v,w) then begin
            writeln('edge ',i,' forms a cycle with edges previously',
                    ' selected for the initial matching');
	    writeln(' execution halts');
	    halt;
	  end; (* if AreEquivalent *)
	  Merge(v,w);
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
      v:= Parity[e]^.end1;
      w:= Parity[e]^.end2;
      if AreEquivalent(v,w) then
	Swap(e)
      else
	Merge(v,w);
    end; (* remove etc *)

    begin (* Initialize *)
      readArcs;
      GetInitialBasis;
      InitEquivalence(NumNode);
      readMatch;
      checkMatch;
      ForSingleton( removeWhenRedundant);
      InitGr(BasisGraph, NumNode);
      Update;
    end; (* initialize *)
