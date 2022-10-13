
{ **** depgraph.i **** }
{ This module implments the operations to be performed on the dependence
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

#include "singletons.i"
#include "transforms.i"


function Mate(e: ELEMENT): ELEMENT;
  { this function returns the mate of the element e }
  begin
    if IsSingleton(e) or IsTransform(e) then
      Mate:= NULLELEMENT
    else
      if (e mod 2) = 0 then
	Mate:= e-1
      else
	Mate:= e+1;
  end;

procedure ForAdjacent( e: ELEMENT; procedure P(o:ELEMENT));
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
       if IsAdjacent(e,BasicXform[i]) then
	 P(BasicXform[i]);
   end; (* if *)
  end; (* For Adjacent  *)

procedure GetInitialBasis;
  { this routine constructs an initial basis of singletons from the 
    edges in a depth first search tree of the input graph.  }

  var
    j: integer;  { counter }

  begin (* get_initial_basis *)
       { initialize }
    for j:= 1 to NumEl do
      InMS[j]:= false;
    BasisSize:= 0;
    NumXform:= 0;
      { end initialize }
    InitSpForest( InputGraph, BasisTree, makeSingleton);
  end; (* get_initial_basis *)



procedure ForElement( procedure P( e: ELEMENT));
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
	write(j);
      end;  

    procedure PrintDepGraph;
      var
	i: ELEMENT;
      begin
	writeln(' Adjacency lists for dependency graph');
	for i:= 1 to NumEl + NumSingle + NumXform do
	  if InMS[i] then begin
	    writeln(' Adjacency list for element ',i);
	    ForAdjacent(i,PrintEl);
	    writeln;
	  end;
      end; (* Print Dep Graph *)  





procedure Swap(e: ELEMENT);
  begin
    InMS[e]:= not InMS[e];
    if not IsSingleton(e) then  { e has a mate }
       begin
	  SwapTrace(e,InMS[e]);  SwapTrace(Mate(e), InMS[e]); 
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
	 begin newBasisGraphTrace( Mstar[i],
			      Parity[Mstar[i]]^.end1, Parity[Mstar[i]]^.end2); 
	AddEdgeGr( BasisGraph, Parity[Mstar[i]]^.end1,
			       Parity[Mstar[i]]^.end2);
	 end; (* for *) 
    end; (* new basis graph *)

  begin (* Update *)
    compactSingles;
    chMstar;
    newBasisGraph;
    updateDepGraph;
    NumXform:= 0;
  end; (* Update *)
