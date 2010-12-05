# SVG to cairo code converter

This project converts SVG files to the equivalent cairo source code. After this conversion, you don't need any SVG rendering library to display the content of the file. [cairo](http://cairographics.org) and the generated source code is everything you need.

## Why?

With [librsvg](http://librsvg.sourceforge.net/), there exists an open-source library that can render SVGs using cairo. However, this library has some bulky dependencies, e.g., GLib. This complicates the distribution of programs using this library.

This converter can replace librsvg at least in thoses cases, where the SVGs are available at compile-time.

## How?

### 1. SVG to cairo XML converter

The first step is to convert the SVG into an XML file describing the cairo drawing commands. This is implemented in `svg2cairoxml.c` using librsvg and cairo's XML surface that was introduced in cairo 1.10.

### 2. cairo XML to cairo code converter

Next, we can convert the generated XML file to source code. This is done using a Lua script that parses and processes the XML file.

## Download & Usage

### Windows

Windows binaries are available by clicking on the download button above. The zip archive contains:

    svg2cairoxml.exe       // SVG to cairo XML converter
    cairoxml2cairo.lua     // cairo XML to source code converter (Lua script)
    lua.exe                // Lua interpreter
    formats/               // directory with supported source code exporters (Lua scripts)
    tests/                 // sample code (see below)
    README.html            // this file in HTML format
    and all necessary DLLs

The easiest way to convert SVG files is by using the command line:

    > svg2cairoxml.exe svg-file xml-file
    > lua.exe cairoxml2cairo.lua [-f format] xml-file source-file

The available formats are described below.

### Linux

On Linux, you have to compile `svg2cairoxml.c` yourself (see below). Additionally, the Lua interpreter is required. The usage is aquivalent to the one on Windows:

    $ ./svg2cairoxml svg-file xml-file
    $ lua cairoxml2cairo.lua [-f format] xml-file source-file

The available formats are described below.

## Output Formats

Currently, `format` can be one of `lua-oocairo`, `c`, and `scrupp`.

### `lua-oocairo`

Creates a Lua file for use with [oocairo](http://git.naquadah.org/?p=oocairo.git) ([manual](http://scrupp.sourceforge.net/manuals/0.4/lua-oocairo/index.html)), a cairo binding for Lua.

Loading the generated file with `require()` or `dofile()` returns a table that contains 3 fields:

1. `width` contains the default width of the graphic.
2. `height` contains the default height of the graphic.
3. `render` is a function that takes a cairo context as argument and renders the graphic using that context.

The default size of the vector image (defined by `width` and `height`) can be changed by calling `cr:scale(sx, sy)` before calling `render`.

### `c`

Produces C source code. The generated file defines 3 functions:

1. `int cairo_code_BASENAME_get_width()` returns the default width of the graphic.
2. `int cairo_code_BASENAME_get_height()` returns the default height of the graphic.
3. `void cairo_code_BASENAME_render(cairo_t *cr)` renders the image using the provided cairo context.

The default size of the vector image (defined by its `width` and `height`) can by changed by calling `cairo_scale(cairo_t *cr, double sx, double sy)` before calling the render function.

`BASENAME` is replaced by the name of the source XML file without suffix (e.g., the basename of `symbol.xml` is `symbol`).

### `scrupp`

Generates a `slua` file. If opened with [Scrupp](http://scrupp.sourceforge.net), the vector graphic is displayed in a window.

## Tests

The `tests` directory contains sample source code that shows how to load images defined by c code or lua files.

## Building

To compile `svg2cairoxml.c`, librsvg and cairo (1.10 or later) with XML surface support are required.

In the cairo library, rendering to an XML surface is not possible by default. Therefore, `--enable-xml=yes` has to be passed to `configure` when compiling cairo.

### Windows

The Windows binaries were created on [Arch Linux](http://www.archlinux.org) using [MinGW](http://www.mingw.org) compiled for Linux. Most required mingw32 libraries were installed from the excellent [Arch User Repository (AUR)](http://aur.archlinux.org).

### Linux

On Linux, the cairo library has to be compiled manually (pass `--enable-xml=yes` to `configure`). You should be able to install all other required libraries with the package manager of your distribution.

Finally, see the `Makefile` for details on how to compile `svg2cairoxml.c`.

An alternative to the manual compilation of cairo is the usage of [wine](http://www.winehq.org) with the provided Windows binaries.

## TODO

* remove redundancy, e.g., no more multiple definitions of the same path

## License

This software is licensed under the [MIT license](http://en.wikipedia.org/wiki/MIT_License).  
© 2010 Andreas Krinke &lt;<andreas.krinke@gmx.de>&gt;.

