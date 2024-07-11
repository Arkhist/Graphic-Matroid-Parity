
{ **** singletons.i **** }
{ This module contains those routines which handle singletons.
  The routines are:

    1. IsSingleton(e: ELEMENT): boolean
	Returns true if e is a singleton.
    2. makeSingleton(v1,v2: VERTEX)
	This routine is a support procedure for the routine GetInitialBasis.
	makeSingleton creates an entry in the Parity data structure for the
	edge (v1,v2) as a singleton.
    3. ForSingleton( procedure P(e: ELEMENT))
	Performs P to every singleton.
    4. compactSingles
	This routine is a support procedure for the routine Update.
	compactSingles removes from the Parity data structure those singletons
	which have been Swap'ed, and renumbers the remaining singletons.

                                                                         }

function IsSingleton( e: ELEMENT): boolean;
  begin
    IsSingleton:= (e > NumEl) and (e <= NumEl+NumSingle )
  end; (* Is Singleton *)
   

  procedure makeSingleton(v1,v2: VERTEX);
    { this procedure adds the edge v1,v2 to Mstar }

    var
      e: EPTR;       { points to an edge }
      pos: ELEMENT;  { array index }
    begin
      new(e,normal);
      e^.end1:= v1;
      e^.end2:= v2;
      NumSingle:= NumSingle + 1;
      pos:= NumEl + NumSingle;

      Parity[pos]:= e;
      Mstar[NumSingle]:= pos;
      BasisSize:= BasisSize + 1;
      InMS[pos]:= true;
    end; (* add_singleton *)
  

procedure ForSingleton( procedure P(e:ELEMENT));
  var
    i: ELEMENT;
  begin
    for i:= NumEl+1 to NumEl + NumSingle do
       P(i);
  end;  (* For Singleton  *)

  
  procedure compactSingles;
       { This procedure renumbers the singletons in the new basis so that
	 they form a contiguous sequence.
	  
	 NumSingle is reset by this procedure.

	 The procedure uses two pointers. 'last' is initially set to the index
	 in Parity of the highest numbered singleton in the old basis.
	 'gap' is initially set to the lowest numbered singleton.
	   In the main loop, last is initially moved to point to the 
	 highest numbered singleton still in the basis.
	 If there is no such singleton, then last will be set to a value less 
	 than that of gap. This is the only case in which last will be less 
	 than gap.
	   In the event that there are singletons remaining in the basis,
	 the procedure then increments gap to point to a singleton not in the 
	 basis. If there is no such singleton, gap will end up pointing to 
	 last.  If there is such a singleton, the singleton pointed to by last  
	 is moved to position 'gap' to make the sequence more contiguous.
	 last is then decremented by one, and the loop repeats.
	 When last<=gap, all singletons in the basis have contiguous numbers 
	 At the end of the repeat loop, last and gap both point to the 
	 last singleton in the new basis, provided there is one.            }


   var 
     gap,last: integer;

   begin (* compact singles *)
     last:= NumEl + NumSingle;    { position of last singleton  }
     gap:= NumEl + 1;             { position of first singleton }
     { main loop }
     repeat
       while not IsInMstar(last) and (last>=gap) do
	 last:= last-1;
       { last now points to highest numbered singleton still in Mstar  }
       
       while IsInMstar(gap) and (gap < last) do
	 gap:= gap+1;
       { gap now points to position of a singleton removed from Mstar 
	  or to last if compaction is completed }

       if (last > gap) then begin { not at end of compaction }
	 Parity[gap]:= Parity[last];
	 InMS[gap]:= true;
	 InMS[last]:= false;
	 last:= last-1;
       end; (* if *)
     until last<=gap;
    { reset number of singletons  }
     if (last < gap) then 
       NumSingle:= 0
     else
       NumSingle:= last-NumEl;
      compactSinglesTrace; 
   end; (* compact singles *)
