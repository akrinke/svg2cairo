# SVG to Cairo code converter

This project converts SVG files to the equivalent Cairo source code. After this conversion, you don't need any SVG rendering library to display the content of the file. [Cairo](http://cairographics.org) and the generated source code is everything you need.

## Why?

With [librsvg](http://librsvg.sourceforge.net/), there exists an open-source library that can render SVGs using Cairo. However, this library has some bulky dependencies, e.g., GLib. This complicates the distribution of programs using this library.

## How?

### SVG to Cairo XML converter

The first step is to convert the SVG into an XML file describing the Cairo drawing commands. This is implemented in `svg2cairoxml.c` using librsvg and the XML surface that was introduced in Cairo 1.10. Rendering to an XML surface is not enabled by default. Therefore, `--enable-xml=yes` has to be passed to `configure` when compiling Cairo.

#### Building

`svg2cairoxml` depends on librsvg and cairo (1.10 or later) with XML surface support enabled. The `Makefile` uses `pkg-config` to find the dependencies.

#### Usage

After the successful compilation of `svg2cairoxml`, you can convert SVG files to Cairo XML files:

    $ ./svg2cairoxml svg-file xml-file

### Cairo XML to Cairo code converter

Now, we can convert the generated XML file to source code. This is done using a Lua script that parses and processes the XML file:

    $ lua cairoxml2cairo.lua xml-file source-file
    
At the moment, this generates a `slua` file. If opened with [Scrupp](http://scrupp.sourceforge.net), the vector graphic is displayed in a window.

## TODO

* support more output formats

## License

This software is licensed under the [MIT license](http://en.wikipedia.org/wiki/MIT_License).  
© 2010 Andreas Krinke &lt;<andreas.krinke@gmx.de>&gt;.

