image_ops
=========

Submodule with some support for operating on images, in particular individual pixel values.

**STATUS**
==========

Mostly functional, though the comments and docs could stand some improvement.

Interlacing support, and maybe some chunks, will probably be added for PNG's; compression is unlikely.

I will probably soon change the loaded PNG to an object with methods, versus the function it is now, since
it's already big enough to be unwieldy.

More energy metrics will be forthcoming, at the very least some from Kwatra's graphcuts papers and maybe something
like histogram-of-gradients.

JPEG is probably down the road somewhere too, and maybe some others.

**DEPENDENCIES**
================

Tested on Lua 5.1.

The `png_encode` module depends on [bitwise operators](https://github.com/ggcrunchy/bitwise_ops), though the module may be swapped out for a
proper bit library if available.