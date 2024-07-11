
{ **** parityGlob.i **** }
{ This module contains those declarations which are independant of the 
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
    Parity: array [ELEMENT] of EPTR;     { parity data structure }
				 { eptr points to edges in input graph } 
    Mstar : array [1..MAXRANK] of ELEMENT; { current basis }
    BasicXform: array [1..MAXRANK] of ELEMENT;  { transforms in current basis }
    NumBasicXform: integer;   { number of transforms in the basis }
    NumEl: integer;           { number of matroid elements in problem }
    NumSingle : integer;      { number of singletons in Mstar }
    NumXform : integer;       { number of transforms in current step }
    InMS : array [ELEMENT] of boolean; { indicates if element is in Mstar }
    BasisSize: 0..MAXRANK;       { rank of matroid basis }
