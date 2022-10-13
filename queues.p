
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
