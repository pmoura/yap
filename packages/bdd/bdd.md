Boolean Decision Making in YAP 			{#BDDs}
==============================

This is an experimental interface to BDD libraries. It is not as
sophisticated as simplecudd, but it should be fun to play around with bdds.

It currently works with cudd only, although it should be possible to
port to other libraries. It requires the ability to dynamically link
with cudd binaries. This works:

- in fedora with standard package
- in osx with hand-compiled and ports package

In ubuntu, you may want to install the fedora rpm, or just download the package from the original
 and compile it.


 + @ref BDDsPL
 + @ref CUDD
