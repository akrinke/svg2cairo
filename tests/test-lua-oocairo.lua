#!/usr/bin/env lua

--[[
Copyright (c) 2010 Andreas Krinke

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

--[[
This script converts an image generated by cairoxml2cairo.lua to a png file.
It requires oocairo, a cairo binding for lua.

oocairo: http://git.naquadah.org/?p=oocairo.git;a=summary
--]]

local Cairo = require "oocairo"

if #arg < 2 then
  print("usage: lua test-lua-oocairo.lua <image lua file> <png file>")
  os.exit(1)
end

local svg = dofile(arg[1])

local surface = Cairo.image_surface_create("argb32", svg.width, svg.height)
local cr = Cairo.context_create(surface)

svg.render(cr)

surface:write_to_png(arg[2])

os.exit()
