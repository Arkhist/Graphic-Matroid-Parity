# Matroid-Parity

This directory contains all files needed to run the cardinality matroid 
parity program based on the algorithm described in Gabow and Stallmann, 
*An Augmenting Path Algorithm for Linear Matroid Parity*, Combinatorica 
6,2 (1986) 123-150. 

In the main directory you will find a Python implementation for Graphic Matroid Parity by
Benjamin Peyrille (Gardes-Sol) made in 2022, who may be contacted at `benjamin.peyrille@grenoble-inp.fr`.

The original implementation in Pascal was written in Summer, 1985, by Gerald M. 
Shapiro under the direction of Matthias (Matt) Stallmann, who may be contacted at
`mfms@ncsu.edu`.

Please see the LICENSE file for information about conditions of use.

If you use this program, let us know how you used it and send us 
any corrections, modifications, or reimplementations.

## Usage

Install the Python library `networkx` (to install: `python -m pip install networkx`).

Run `main.py` with `python` (3.10+), which will read from standard input (stdin) an input with the following format (edges come in pairs, so edge 2k-1 and 2k form a pair):

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

## Sample inputs

All have a `.txt` extension.

* `1986-Combinatorica-Gabow_Fig_2_2` - example from the paper

* `tst1, tst2, tst3` - some small examples

* `2016-Theory_Seminar-Fig_*` - examples (figures) from the paper *A Gentle Introduction to Matroid Algorithmics*, in `2016-Theory_Reading_Group.pdf`; pictures related to these are in the related pdf files

* `stsh_counterexample` - example corresponding to an erroneous result in the Pascal implementation, fixed in the Python implementation (no augmenting step is found in the Pascal implementation while there should be one.)

* `stsh_old_crash1` and `stsh_old_crash3` - two examples causing a crash in the Pascal implementation during a blossom step.

## Technical details

The implementation of the base graph in `base_graph.py`, used only to test the validity of a matching and to get an initial matching, uses the Python library `networkx`. For longevity, an implementation that does not use `networkx` could be interesting.

- `main.py` executes the entire input parsing to solving pipeline. For more details on the execution, at the top of the file you can set `solver.VERBOSE = True`.

- `input_parsing.py` transforms the information from stdin into a BaseGraph defined in `base_graph.py`.

- `base_graph.py` is an interface for a standard graph data structure.

- `union_find.py` is a very short and non-optimal Union-Find implementation for Kruskal's algorithm.

- `dependency_graph.py` implements the dependency graph for graphical matroid parity. A few adjustments are needed to make it handle more general matroids.

- `solver.py` contains the Linear Matroid Parity algorithm.

## Fix

The original implementation as well as the paper specification of the algorithm contains a subtle bug in the definition of the search path for a transform with a reverse pointer, which causes the original implementation to give erroneous results (and sometimes crash?).

The definition of a search path for a transform `e` with a reverse pointer `g` and parent pointer `f` is the following: `e P(g, bar(t0))^r P(f)`.

By replacing `P(g, bar(t0))^r` with `(P(g, t0)-t0)^r`, it seems we get the proper results.
