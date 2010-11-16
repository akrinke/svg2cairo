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
int cairo_code_$basename_get_width() { return $width; }
int cairo_code_$basename_get_height() { return $height; }
void cairo_code_$basename_render(cairo_t *cr) {
cairo_surface_t *temp_surface;
cairo_t *old_cr;
cairo_pattern_t *pattern;
cairo_matrix_t matrix;
]],

    post = "}"
  },
  
  surface = {
    pre = [[
old_cr = cr;
temp_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, $width, $height);
cr = cairo_create(temp_surface);]],
  },
  
  fill   = {post = "cairo_fill_preserve(cr);\n /********************/"},
  stroke = {post = "cairo_stroke_preserve(cr);\n/********************/"},
  mask   = {},
  
  operator        = "cairo_set_operator(cr, CAIRO_OPERATOR_$value);",
  tolerance       = "cairo_set_tolerance(cr, $value);",
  antialias       = "cairo_set_antialias(cr, CAIRO_$value);",
  ["fill-rule"]   = "cairo_set_fill_rule(cr, CAIRO_FILL_RULE_$value);",
  ["line-width"]  = "cairo_set_line_width(cr, $value);",
  ["miter-limit"] = "cairo_set_miter_limit(cr, $value);",
  ["line-cap"]    = "cairo_set_line_cap(cr, CAIRO_$value);",
  ["line-join"]   = "cairo_set_line_join(cr, CAIRO_$value);",

  linear          = "pattern = cairo_pattern_create_linear($x1, $y1, $x2, $y2);",
  radial          = "pattern = cairo_pattern_create_radial($x1, $y1, $r1, $x2, $y2, $r2);",
  solid           = function(state, value) return format("pattern = cairo_pattern_create_rgba(%s);", gsub(value, " ", ",")) end,
  ["color-stop"]  = function(state, value) return format("cairo_pattern_add_color_stop_rgba(pattern, %s);", gsub(value, " ", ",")) end,
  extend          = "cairo_pattern_set_extend(pattern, CAIRO_$value);",
  filter          = "cairo_pattern_set_filter(pattern, CAIRO_$value);",
  
  ["source-pattern"] = {
    post = function(state, value)
      if state.last_environment == "surface" then
        return [[
cairo_destroy(cr);
cr = old_cr;
cairo_set_source_surface(cr, temp_surface, 0, 0);
cairo_surface_destroy(temp_surface);]]
      else
        return [[
cairo_set_source(cr, pattern);
cairo_pattern_destroy(pattern);]]
      end
    end
  },
  
  ["mask-pattern"] = {
    post = function(state, value)
      if state.last_environment == "surface" then
        return [[
cairo_mask_surface(cr, temp_surface, 0, 0);
cairo_surface_destroy(temp_surface);]]
      else
        return [[
cairo_mask(cr, pattern);
cairo_pattern_destroy(pattern);]]
      end
    end
  },
  
  path = function(state, value)
    local s = {"cairo_new_path(cr);"}
    local stack = {}
    for x in gmatch(value, "%S+") do
      local n = tonumber(x)
      if n then
        stack[#stack+1] = x
      else
        if x == "m" then
          s[#s+1] = format("cairo_move_to(cr, %s, %s);", unpack(stack))
        elseif x == "l" then
          s[#s+1] = format("cairo_line_to(cr, %s, %s);", unpack(stack))
        elseif x == "c" then
          s[#s+1] = format("cairo_curve_to(cr, %s, %s, %s, %s, %s, %s);", unpack(stack))
        elseif x == "h" then
          s[#s+1] = "cairo_close_path(cr);"
        end
        stack = {}
      end
    end
    return concat(s, "\n")
  end,      
  
  matrix = function(state, value) 
    local s = format("cairo_matrix_init(&matrix, %s);\n", gsub(value, " ", ","))
    if state.last_environment == "surface" then
      return s .. [[
matrix.x0 = 0;
matrix.y0 = 0;
cairo_set_matrix(cr, &matrix);]]
    else
      return s .. "cairo_pattern_set_matrix(pattern, &matrix);"
    end
  end
}
