#!/usr/bin/env lua

--[[
Copyright (c) 2010, 2014 Andreas Krinke

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

local formats = "c lua-oocairo scrupp"

-- default export filter
local format = "lua-oocairo"
local infile, outfile

-- collect command line argument
if #arg == 2 then
  infile  = arg[1]
  outfile = arg[2]
elseif #arg == 4 and arg[1] == "-f" and string.find(formats, arg[2], 1, true) then
  format  = arg[2]
  infile  = arg[3]
  outfile = arg[4]
else
  print([[
Usage: lua cairoxml2cairo.lua [-f format] xml-file source-file
Available formats: ]] .. formats)
  os.exit()
end

-- try to load the source code format definitions
local success, replacements = pcall(require, "formats." .. format)

if not success then
  print(string.format([[
Error loading format %s:
%s
Is %s.lua missing in directory 'formats'?]], format, replacements, format))
  os.exit()
end

-- list of tags, that start a pattern definition
local pattern_tags = {
  solid = true,
  linear = true,
  radial = true
}

-- stores the current state of cairo
local state = {}

-----------------------------------------------------------------------------
-- Function Definitions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Simple XML Parser
-- source: http://lua-users.org/wiki/LuaXml
local function parseargs(s)
  local arg = {}
  string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end

local function collect(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w%-:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=parseargs(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[stack.n].label)
  end
  return stack[1]
end
-- End Simple XML Parser
-----------------------------------------------------------------------------

--- Extracts the basename (without suffix) from a path
-- @patam path Path to extract the basename from.
-- @return basename of the file
function basename(path)
	local file = path:match("([^\\/:]*)$")
	local basename, ext = file:match("^%.*(.+)%.([^%.]-)$")
	if not basename then
		basename = file:match("^%.*(.*)$")
	end
	return (basename:gsub("[%.-]", "_"))
end

--- Outputs the source code corresponding to the current tag.
-- For each start and end tag, different source code can be defined.
-- @param fh       Output filehandle.
-- @param basename Basename of the output file.
-- @param kind     Either "pre" (start tag was parsed)
--                 or "post" (stop tag was parsed).
-- @param t        Table containing information about the current tag.
local function output(fh, basename, kind, t)
  local label = t.label
  if label == "svg" then
    error("svg tag detected\nPlease provide a cairo xml file, not an svg file.")
  end
  
  if kind == "pre" then
    if pattern_tags[label] then
      state.current_environment = "pattern"
    else
      state.current_environment = nil
    end
  else -- "post"
    if label == "surface" then
      state.last_environment = "surface"
    elseif pattern_tags[label] then
      state.last_environment = "pattern"
    end
  end
  
  local rep = replacements[label]
  if not rep then
    error("not supported tag: " .. label)
  end
  
  local s
  if kind == "pre" then
    if type(rep) == "table" then
      rep = rep.pre
    end
  else
    if type(rep) == "table" then
      rep = rep.post
    else
      rep = nil
    end
  end
  
  if type(rep) == "string" then
    s = rep
  elseif type(rep) == "function" then
    s = rep(state, t[1])
  end
  if s then
    s = string.gsub(s, "$basename", basename)
    s = string.gsub(s, "$value", t[1])
    s = string.gsub(s, "$(%w+)", t.xarg)
    fh:write(s, "\n")
  end
end

--- Processes the table generated by the XML parser.
-- @param fh Output filehandle.
-- @param t  Table generated by collect().
-- @see collect.
local function process(fh, basename, t)
  for _,child in ipairs(t) do
    if type(child) == "table" then
      output(fh, basename, "pre", child)
      process(fh, basename, child)
      output(fh, basename, "post", child)
    end
  end
end

-----------------------------------------------------------------------------
-- Main
-----------------------------------------------------------------------------

-- open the input and output file
local fh_in  = assert(io.open(infile))
local fh_out = assert(io.open(outfile, "w"))

-- read and parse the whole xml file
local t = collect(fh_in:read("*a"))

-- process the resulting table
process(fh_out, basename(outfile), t)
