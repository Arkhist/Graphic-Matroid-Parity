
{ **** userGlob.i **** }
{ This module contains all global type and variable decalrations which 
  depend upon the specific matroid or upon the implementation of required
  support modules, (see heading comments in parpgm.p). }

const
  NULLELEMENT = 0;     
  MAXE = 100;           { maximum number of elements in a matroid , }
			{ including transforms and singletons.      }
  LOGMAXELEMENTS = 7;	{ log to the base 2 of # of elements }
  MAXDIGIT = 3;         { the maximum numbe of digits used to repesent
			  an element. Used in output routines }
  MAXV = 100;            { maximum number of vertices in a graph }
  MAXRANK = 99;         { maximum rank of an input matroid }
  DELIM = '$';          { this delimiter appears around each element
			   number in the output    }
type
    ELEMENT = 0..MAXE;   { ordinal type for matroid elements }
    VERTEX = 1..MAXV;    { ordinal type for vertices in graph module }
    EPTR = ^eltype;
    { "eltype" is a record describing the matroid elements. }
    elcases = (normal, transform);  { two kinds of elements }
    eltype = record            
	      case elcases of
	        normal: (end1, end2: VERTEX); { endpoints of edge }
		transform: (el1, el2: ELEMENT); { tips of transform }
             end;
    QDATA = ELEMENT;     { type definition for items to be enqueued }
    INDICATOR = array [ELEMENT] of boolean; 
			 { used for passing parameters to output routine }
{ the following types are used to implement a graph  }
    aptr = ^adjNode;
    adjNode = record       { node on adjacency list }
               vnum: VERTEX; { number of vertex on list }
               next : aptr;     { pointer }
              end; (* adj_node *)
    GRAPH = record
             numVertex: integer;
	     adjacency: array [VERTEX] of aptr;
	    end;  (* GRAPH *) 	
{ the type FOREST is used to implement a spanning tree   }

    FOREST = record
	      pre: array [VERTEX] of integer;
	      high: array [VERTEX] of integer;
	     end; (* FOREST *)



 var
    InputGraph: GRAPH;              { the input graph itself        }
    BasisTree: FOREST;              { spanning forest of current basis }
