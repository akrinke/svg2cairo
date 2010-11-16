# SVG to Cairo code converter

This project converts SVG files to the equivalent Cairo source code. After this conversion, you don't need any SVG rendering library to display the content of the file. [Cairo](http://cairographics.org) and the generated source code is everything you need.

## Why?

With [librsvg](http://librsvg.sourceforge.net/), there exists an open-source library that can render SVGs using Cairo. However, this library has some bulky dependencies, e.g., GLib. This complicates the distribution of programs using this library.

This converter can replace librsvg at least in thoses cases, where the SVGs are available at compile-time.

## How?

### SVG to Cairo XML converter

The first step is to convert the SVG into an XML file describing the Cairo drawing commands. This is implemented in `svg2cairoxml.c` using librsvg and the XML surface that was introduced in cairo 1.10.

In the cairo library, rendering to an XML surface is not enabled by default. Therefore, `--enable-xml=yes` has to be passed to `configure` when compiling cairo.

#### Building

`svg2cairoxml` depends on librsvg and cairo (1.10 or later) with XML surface support enabled. The `Makefile` uses `pkg-config` to find the dependencies.

#### Usage

After the successful compilation of `svg2cairoxml`, you can convert SVG files to cairo XML files:

    $ ./svg2cairoxml svg-file xml-file

### Cairo XML to Cairo code converter

Now, we can convert the generated XML file to source code. This is done using a Lua script that parses and processes the XML file:

    $ lua cairoxml2cairo.lua [-f format] xml-file source-file
    
`format` can be either `lua-oocairo` (default), `c`, or `scrupp`.
    
#### Output Formats

##### lua-oocairo

Creates a Lua file for use with [oocairo](http://git.naquadah.org/?p=oocairo.git) ([manual](http://scrupp.sourceforge.net/manuals/0.4/lua-oocairo/index.html)), a cairo binding for Lua.

Loading the generated file with `require()` or `dofile()` returns a table that contains 3 fields:

1. `width` contains the default width of the graphic.
2. `height` contains the default height of the graphic.
3. `render` is a function that takes a cairo context as argument and renders the graphic using that context.

The default size of the vector image (defined by `width` and `height`) can by changed by calling `cr:scale(sx, sy)` before calling `render`.

##### c

Produces C source code. The generated file defines 3 functions:

1. `int cairo_code_BASENAME_get_width()` returns the default width of the graphic.
2. `int cairo_code_BASENAME_get_height()` returns the default height of the graphic.
3. `void cairo_code_BASENAME_render(cairo_t *cr)` renders the image using the provided cairo context.

The default size of the vector image (defined by its `width` and `height`) can by changed by calling `cairo_scale(cairo_t *cr, double sx, double sy)` before calling the render function.

`BASENAME` is replaced by the name of the source xml file without suffix (e.g., the basename of `symbol.xml` is `symbol`).

##### scrupp

Generates a `slua` file. If opened with [Scrupp](http://scrupp.sourceforge.net), the vector graphic is displayed in a window.

## Tests

The `tests` directory contains sample source code that shows how to load images defined by c code or lua files.

## TODO

* remove redundancy, e.g., no more multiple definitions of the same path

## License

This software is licensed under the [MIT license](http://en.wikipedia.org/wiki/MIT_License).  
© 2010 Andreas Krinke &lt;<andreas.krinke@gmx.de>&gt;.

