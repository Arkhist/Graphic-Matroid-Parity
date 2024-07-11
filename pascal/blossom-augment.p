
{ **** blossom-augment.i **** }
{ This module contains the routine blossomAugment called from the routine
  scan. }


    procedure blossomAugment(e,f:ELEMENT);
      { This procedure examines the paths from e and f back to their
	roots. If the paths join, then a blossom is formed.
	If the paths do not join, an augmentation is called for. }
      var
	bud: ELEMENT;  { the first element on both paths which is
			 followed by its mate }
	t1,t2: ELEMENT; { the predecessors of bud on the path back
			  from e and f, respectivly }
      
      procedure tracePath(fromHere, toThere: ELEMENT;
			  procedure P(e: ELEMENT));
	  { tracePath calls itself recursivly to trace the path from
	    node fromHere to node toThere.
	    procedure P is performed for each parity pair on the path }
	var
	  fH: ELEMENT; { equal to fromHere when fromHere is not a transform,
			 equal to a tip of fromHere when fromHere is 
			 a transform }

	
	begin  (* trace Path *)
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
	  end; (* if *)
	end; (* trace Path *)


      procedure quickTrace( fromHere, toThere: ELEMENT; 
			    procedure P(e:ELEMENT));
	  { this procedure traces the path from fromHere to toThere, 
	    ignoring reverse pointers 
	     procedure P is performed for every parity pair encountered on the
	     quick trace path }
	
	begin  (* trace Path *)
	  if fromHere <> toThere then begin
	    P(fromHere);
	    quickTrace(SearchLabel[fromHere].back, toThere, P);
	  end; (* if *)
	end; (* quick trace *)
      

      procedure blossom(e,f,bud, tip1,tip2: ELEMENT);
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
	  labelTips:= not isTrueTips(tip1,tip2);
	  makeXform:= not (labelTips or Equivalent(tip1,tip2));
	  ePathPtr:= e;
	  fPathPtr:= f;
	  MakeEquivalent(e,f);
	  { end initializations }
           blossomTrace(bud,tip1,tip2,not labelTips);   

	{ trace paths back from e and f and assign lablels }
	   { set PathPtr's to point to first element on each path
	     whose mate needs a label  }
	  ePathPtr:= pruneList( ePathPtr);
	  fPathPtr:= pruneList( fPathPtr);

	  repeat
	    { trace 'e' path }
	    while (Serial[ePathPtr] > Serial[fPathPtr]) and
		    (ePathPtr <> bud) do begin
	      MakeEquivalent(e,ePathPtr);
	      if (Mate(ePathPtr) <> tip1) or labelTips then
		  giveLabel(Mate(ePathPtr), f,e);
	      ePathPtr:= pruneList( SearchLabel[ePathPtr].back);
	    end; (* while *)
	    { trace f path  }
	    while (Serial[fPathPtr] > Serial[ePathPtr]) and
		    (fPathPtr <> bud) do begin
	      MakeEquivalent(f,fPathPtr);
	      if (Mate(fPathPtr) <> tip2) or labelTips then
		  giveLabel(Mate(fPathPtr), e,f);
	      fPathPtr:= pruneList( SearchLabel[fPathPtr].back);
	    end; (* while *)
          until (ePathPtr = bud) and (fPathPtr = bud);

	 if makeXform then begin
	   x:= CreateTransform(tip1, tip2, bud);
	   giveLabel(x,f,e);
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
      

      function closestCommonAncestor(e,f: ELEMENT): ELEMENT;
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
	 end;

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
	quickTrace( e, NULLELEMENT, mark);
	{ second pass }
	cca:= NULLELEMENT;
	quickTrace(f, NULLELEMENT, comparePaths);
	closestCommonAncestor:= cca;

	if cca <> NULLELEMENT then
	   { blossom found, clean up OnPath for next time }
	  quickTrace( e, NULLELEMENT, eraseMarks);
      end; (* closest Common Ancestor *)

    begin (* blossom Augment *)
      if not Equivalent(e,f) then begin
	bud:= closestCommonAncestor(e,f);
	if bud = NULLELEMENT then
	  augment(e,f)
	else
	  blossom(e,f,bud, t1,t2);
      end; (* if *)
    end; (* blossom augment *)
