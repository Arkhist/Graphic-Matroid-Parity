
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
