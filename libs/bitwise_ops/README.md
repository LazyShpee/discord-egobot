bitwise_ops
===========

Submodule consisting of routines built largely atop bitwise operations.

**STATUS**
==========

Non-count operations are mostly functional, though the comments and docs could stand some improvement.

This is pretty open-ended feature-wise, as a lot of things fall into the category of bitwise operations,
so things will be added as they're needed.

The "operators" module can be ignored if the require()'ing code knows it has a proper bit library handy; it is
merely a way to put the detection / fallback logic all in one place.

**DEPENDENCIES**
================

Tested on Lua 5.1. (Bit vector test [here](https://github.com/ggcrunchy/Strays/blob/master/Unit%20Tests/BitVector.lua).)

The `vector` module depends on [unsigned division constants](https://github.com/ggcrunchy/corona-sdk-snippets/blob/master/number_ops/divide.lua)
support, which is in the rather unstable `number_ops` directory (logically it's four or five submodules, I think). However, the division module
will probably be one of the survivors. In any event, the function in question is easy enough to inline.