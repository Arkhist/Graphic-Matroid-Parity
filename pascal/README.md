# Matroid-Parity
This directory contains all files needed to run the cardinality matroid 
parity program based on the algorithm described in Gabow and Stallmann, 
*An Augmenting Path Algorithm for Linear Matroid Parity*, Combinatorica 
6,2 (1986) 123-150. The program was written in Summer, 1985, by Gerald M. 
Shapiro under the direction of Matthias (Matt) Stallmann, who may be contacted at
`mfms@ncsu.edu`

Please see the LICENSE file for information about condiditions of use.

If you use this program, let me know how you used it and send me 
any corrections, modifications, or reimplementations (email: mfms@ncsu.edu).

To compile with `fpc`, use the `-Miso` option.

** CAUTION **
*There appears to be a bug. More information is in the Counterexample subdirectory. The relevant input is counterexample.txt.*

Input to the parity program (from stdin) takes the following format:
(edges come in pairs, so edge 2k-1 and 2k form a pair)
```
        <number of vertices>
        <edge 1 -- two numbers giving the endpoints>
        <edge 2>
        ...
        <edge 2m-1>
        <edge 2m>
        0 0
        <edge # of 1st edge initial matching> ** Edge number! **
        <edge # of 2nd edge initial matching>
        ...
        <edge # of 2k-1st edge in initial matching>
        <edge # of 2kth edge in initial matching>
        0
        <comments>
```
The specification of an initial matching is optional.
Comments can be appended to any line of the input. Anything beyond the first two numbers is ignored.

All modules of the parity program are consolidated in `parpgm.p`.

The function IncreaseMatching implements the algorithm of an earlier version of our paper.
**Note:** This program is independent of the type of matroid. Other types of matroids can be used if appropriate supporting routines for defining transforms, dependence graph adjacencies, etc. are provided.

The modules are also available in the following separate files.

`userGlob.p` -- contains definitions of various global constants, types,
	and variables that the user may want to change (e.g. maximum
	number of elements allowed).

`parityGlob.p` -- contains global definitions that are independent of the
	type or size of matroids used.

`input-output.p` -- contains I/O routines; comments in this module explain
	the required format for the input.

`trace-module.p` -- contains routines that do trace printout of the progress
	of the algorithm (these should be modified to suit the taste of the
	user -- some could be turned into "stubs" if the corresponding print-
	out is not wanted).

`blossom-augment.p` -- contains routines that perform blossom and augment
	steps.

`depgraph.p` -- contains routines that access the dependence graph. Two
	subordinate modules, transforms.p and singletons.p handle situations
	unique to transforms and singletons.

`graph.p` -- implements an abstract data type GRAPH (as described in AHU 1983).
	This module may be useful in other graph algorithms, also.

`spforest.p` -- this module maintains a spanning forest (i.e. the current base),
	using preorder numbering to determine adjacencies of elements not
	in the forest.

`queues.p` -- general purpose routines for queues

`equiv.p` -- maintains the Union/Find structures using parent pointers and
	data compression.

The comments in the code, along with this outline should be adequate to explain how the code functions. If not, more detailed documentation can be provided -- contact mfms@ncsu.edu.

## Sample inputs

All have a `.txt` extension.

* `1986-Combinatorica-Gabow_Fig_2_2` - example from the paper

* `tst1, tst2, tst3` - some small examples

* `2016-Theory_Seminar-Fig_*` - examples (figures) from the paper *A Gentle Introduction to Matroid Algorithmics*, in `2016-Theory_Reading_Group.pdf`; pictures related to these are in the related pdf files

