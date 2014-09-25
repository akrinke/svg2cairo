--[[
Copyright (c) 2010-2014 Andreas Krinke

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

local string = string
local format = string.format
local gmatch = string.gmatch
local gsub = string.gsub
local lower = string.lower
local match = string.match

local concat = table.concat
local tonumber = tonumber
local unpack = unpack

return {
  image = {
    pre = [[
local Cairo = require "oocairo"

return {
width = $width,
height = $height,
render = function(cr)

local temp_surface
local old_cr
local line_width = 1
local pattern
local matrix
]],

    post = "end}"
  },

  surface = {
    pre = [[
old_cr = cr
temp_surface = Cairo.image_surface_create("argb32", $width, $height)
cr = Cairo.context_create(temp_surface)]],
  },

  fill   = {post = "cr:fill_preserve()\n----------------------"},
  stroke = {post = "cr:stroke_preserve()\n----------------------"},
  paint  = {post = "cr:paint()\n----------------------"},
  mask   = {},

  operator        = function(state, value) return format('cr:set_operator("%s")', lower(value)) end,
  tolerance       = "cr:set_tolerance($value)",
  antialias       = function(state, value) return format('cr:set_antialias("%s")', lower(value)) end,
  ["fill-rule"]   = function(state, value) return format('cr:set_fill_rule("%s")', lower(gsub(value, "_", "-"))) end,
  ["line-width"]  = "line_width = $value\ncr:set_line_width(line_width)",
  ["miter-limit"] = "cr:set_miter_limit($value)",
  ["line-cap"]    = function(state, value) return format('cr:set_line_cap("%s")', lower(match(value, "_([^_]-)$"))) end,
  ["line-join"]   = function(state, value) return format('cr:set_line_join("%s")', lower(match(value, "_([^_]-)$"))) end,

  linear          = "pattern = Cairo.pattern_create_linear($x1, $y1, $x2, $y2)",
  radial          = "pattern = Cairo.pattern_create_radial($x1, $y1, $r1, $x2, $y2, $r2)",
  solid           = function(state, value) return format("pattern = Cairo.pattern_create_rgba(%s)", gsub(value, " ", ",")) end,
  ["color-stop"]  = function(state, value) return format("pattern:add_color_stop_rgba(%s)", gsub(value, " ", ",")) end,
  extend          = function(state, value) return format('pattern:set_extend("%s")', lower(match(value, "_(.*)"))) end,
  filter          = function(state, value) return format('pattern:set_filter("%s")', lower(match(value, "_(.*)"))) end,

  ["source-pattern"] = {
    post = function(state, value)
      if state.last_environment == "surface" then
        return [[
cr = old_cr
cr:set_source(temp_surface, 0, 0)
temp_surface = nil]]
      else
        return "cr:set_source(pattern)"
      end
    end
  },

  ["mask-pattern"] = {
    post = function(state, value)
      if state.last_environment == "surface" then
        return "cr:mask(temp_surface, 0, 0)"
      else
        return "cr:mask(pattern)"
      end
    end
  },

  path = function(state, value)
    local s = {"cr:new_path()"}
    local stack = {}
    for x in gmatch(value, "%S+") do
      local n = tonumber(x)
      if n then
        stack[#stack+1] = x
      else
        if x == "m" then
          s[#s+1] = format("cr:move_to(%s, %s)", unpack(stack))
        elseif x == "l" then
          s[#s+1] = format("cr:line_to(%s, %s)", unpack(stack))
        elseif x == "c" then
          s[#s+1] = format("cr:curve_to(%s, %s, %s, %s, %s, %s)", unpack(stack))
        elseif x == "h" then
          s[#s+1] = "cr:close_path()"
        end
        stack = {}
      end
    end
    return concat(s, "\n")
  end,

  matrix = function(state, value)
    if state.last_environment == "gradient" then
      return format("matrix = {%s}\npattern:set_matrix(matrix)", gsub(value, " ", ","))
    else
      return format("cr:set_line_width(line_width * %s)", match(value, "%S+"))
    end
  end
}
