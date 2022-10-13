
{ **** trace-module.t **** }
{ This module contains all routines which provide summary information about the
  calculations.
  The trace routine for procedure foo is named fooTrace.      }

type 
  Indicator = array [ELEMENT] of boolean;

var
  InBlossomTrace: boolean;  { indicator for output formatting }

procedure augmentTrace;
  begin
    writeln('augment step-');
  end;

procedure blossomTrace(bud,tip1,tip2:ELEMENT; trueTips: boolean);
  begin
    InBlossomTrace:= true;
    writeln('blossom step-');
    writeln('          t0=',DELIM,tip1:MAXDIGIT,DELIM,
            '    t1=',DELIM,tip2:MAXDIGIT,DELIM,
            '    b=',DELIM,bud:MAXDIGIT,DELIM);
    if trueTips then
      writeln('          true tips')
    else
      writeln('          not true tips');
  end;


procedure checkAdjTrace(e,f: ELEMENT; equiv,adjacent: boolean);
  begin
    if adjacent then 
     if equiv then
      writeln('     ',DELIM,f:MAXDIGIT,DELIM,': ', DELIM,f:MAXDIGIT,DELIM,
	      ' equivalent to ',DELIM,e:MAXDIGIT,DELIM,
		    ', so do nothing')
     else
       write('     ',DELIM,f:MAXDIGIT,DELIM,': ');
  end;

procedure compactSinglesTrace;
  var
    index: integer;
  begin
    InBlossomTrace:= false;  { initialize formatting boolean }
    writeln;
    writeln;
    writeln('*************  enter IncreaseMatching ***************');
    writeln;
    writeln(' there are now ',NumSingle:MAXDIGIT,' singletons');
    writeln(' they are:');
    for index:= NumEl+1 to NumEl+ NumSingle do 
	  writeln(DELIM,index:MAXDIGIT,DELIM,':',
		  Parity[index]^.end1,Parity[index]^.end2);  
  end;

procedure CreateTransformTrace(z,x,y,bud: ELEMENT);
  begin
    InBlossomTrace:= false;
    writeln('           create ',DELIM,z:MAXDIGIT,DELIM,'=T(',
	    DELIM,x:MAXDIGIT,DELIM,',',DELIM,y:MAXDIGIT,DELIM,',',
	    DELIM,bud:MAXDIGIT,DELIM,'),  ');
    write('          ');   { format for label trace }
  end;


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
  end;

procedure newBasisGraphTrace(e: ELEMENT; v,w: VERTEX);
  begin
  end;

procedure readMatchTrace(initMatch: INDICATOR; num: integer);
  var arc: integer;
  begin
     writeln('Initial Matching List'); 
     for arc:=1 to num do
       if initMatch[arc] then
         writeln(' edge', arc,' endpoints:',
		    Parity[arc]^.end1,Parity[arc]^.end2); 
  end;

procedure scanTrace(e: ELEMENT);
  begin
    writeln;
    writeln;
    writeln('scan label on ',DELIM,e:MAXDIGIT,DELIM,' ; adjacent to--');
  end;

procedure SwapTrace(e: ELEMENT; putIn: boolean);
  begin
    if putIn then
      writeln('        put element ',DELIM,e:MAXDIGIT,DELIM,' in basis')
    else
      writeln('        removed element ',DELIM,e:MAXDIGIT,DELIM,' from basis');
  end;

procedure tryToGrowTrace(e,f,fbar: ELEMENT; equiv,unlabelled,pending,
			 mateUnlabelled,degen: boolean);
  begin
    if unlabelled or pending then begin
      write('     ',DELIM,f:MAXDIGIT,DELIM,': ');
    if equiv then
      writeln(DELIM,f:MAXDIGIT,DELIM,' equivalent to ',DELIM,e:MAXDIGIT,DELIM,
	     ', so do nothing')
    else if degen then
      writeln(DELIM,f:MAXDIGIT,DELIM,
	      ' is a tip of a degenerate blossom, so do nothing.')
    else if pending then 
	    writeln('s[',DELIM,f:MAXDIGIT,DELIM,']>s[',DELIM,e:MAXDIGIT,DELIM,
		    '] ,so do nothing')
    else if not mateUnlabelled then
	    writeln(DELIM,fbar:MAXDIGIT,DELIM,
		    ' already labelled so do nothing');
    end;
  end;
