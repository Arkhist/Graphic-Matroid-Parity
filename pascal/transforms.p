
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
    end; (* else *)
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
      isAdjElEl:= IsInCycle( Parity[inel]^.end1, Parity[inel]^.end2,
        		     Parity[outel]^.end1, Parity[outel]^.end2,
        		     BasisTree);
    end;

  function isAdjXEl( x,e: ELEMENT): boolean;
    begin
      isAdjXEl:= isAdjElEl(Parity[x]^.el1, e) <> isAdjElEl( Parity[x]^.el2, e);
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
    new(p,transform);
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
    CreateTransformTrace(xnum, x,y,b);  
  end; (* Create Transform *)


function FirstTip(e: ELEMENT): ELEMENT;
  begin
    FirstTip:= Parity[e]^.el1;
  end;

function SecondTip(e: ELEMENT): ELEMENT;
  begin
    SecondTip:= Parity[e]^.el2;
  end;
