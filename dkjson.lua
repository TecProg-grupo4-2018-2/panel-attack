    --[==[

David Kolf's JSON module for Lua 5.1/5.2
========================================

*Version 2.1*

This module writes no global values, not even the module table.
Import it using

    json = require ('dkjson')

Exported functions and values:

`json.encode (object [, state])`
--------------------------------

Create a string representing the object. `Object` can be a table,
a string, a number, a boolean, `nil`, `json.null` or any object with
a function `__tojson` in its metatable. A table can only use strings
and numbers as keys and its values have to be valid objects as
well. It raises an error for any invalid data types or reference
cycles.

`state` is an optional table with the following fields:

  - `indent`
    When `indent` (a boolean) is set, the created string will contain
    newlines and indentations. Otherwise it will be one long line.
  - `keyorder`
    `keyorder` is an array to specify the ordering of keys in the
    encoded output. If an object has keys which are not in this array
    they are written after the sorted keys.
  - `level`
    This is the initial level of indentation used when `indent` is
    set. For each level two spaces are added. When absent it is set
    to 0.
  - `buffer`
    `buffer` is an array to store the strings for the result so they
    can be concatenated at once. When it isn't given, the encode
    function will create it temporary and will return the
    concatenated result.
  - `bufferlen`
    When `bufferlen` is set, it has to be the index of the last
    element of `buffer`.
  - `tables`
    `tables` is a set to detect reference cycles. It is created
    temporary when absent. Every table that is currently processed
    is used as key, the value is `true`.

When `state.buffer` was set, the return value will be `true` on
success. Without `state.buffer` the return value will be a string.

`json.decode (string [, position [, null]])`
--------------------------------------------

Decode `string` starting at `position` or at 1 if `position` was
omitted.

`null` is an optional value to be returned for null values. The
default is `nil`, but you could set it to `json.null` or any other
value.

The return values are the object or `nil`, the position of the next
character that doesn't belong to the object, and in case of errors
an error message.

Two metatables are created. Every array or object that is decoded gets
a metatable with the `__jsontype` field set to either `array` or
`object`. If you want to provide your own metatables use the syntax

    json.decode (string, position, null, objectmeta, arraymeta)

`<metatable>.__jsonorder`
-------------------------

`__jsonorder` can overwrite the `keyorder` for a specific table.

`<metatable>.__jsontype`
------------------------

`__jsontype` can be either `"array"` or `"object"`. This is mainly useful
for tables that can be empty. (The default for empty tables is
`"array"`).

`<metatable>.__tojson (self, state)`
------------------------------------

You can provide your own `__tojson` function in a metatable. In this
function you can either add directly to the buffer and return true,
or you can return a string. On errors nil and a message should be
returned.

`json.null`
-----------

You can use this value for setting explicit `null` values.

`json.version`
--------------

Set to `"dkjson 2.1"`.

`json.quotestring (string)`
---------------------------

Quote a UTF-8 string and escape critical characters using JSON
escape sequences. This function is only necessary when you build
your own `__tojson` functions.

`json.addnewline (state)`
-------------------------

When `state.indent` is set, add a newline to `state.buffer` and spaces
according to `state.level`.

LPeg support
------------

When the local configuration variable
`always_try_using_lpeg` is set, this module tries to load LPeg to
replace the functions `quotestring` and `decode`. The speed increase
is significant. You can get the LPeg module at
  <http://www.inf.puc-rio.br/~roberto/lpeg/>.
When LPeg couldn't be loaded, the pure Lua functions stay active.

In case you don't want this module to require LPeg on its own,
disable this option:

    --]==]
    local always_try_using_lpeg = true
    --[==[

In this case you can later load LPeg support using

### `json.use_lpeg ()`

Require the LPeg module and replace the functions `quotestring` and
and `decode` with functions that use LPeg patterns.
This function returns the module table, so you can load the module
using:

    json = require "dkjson".use_lpeg()

Alternatively you can use `pcall` so the JSON module still works when
LPeg isn't found.

    json = require "dkjson"
    pcall (json.use_lpeg)

### `json.using_lpeg`

This variable is set to `true` when LPeg was loaded successfully.

You can contact the author by sending an e-mail to 'kolf' at the
e-mail provider 'gmx.de'.

---------------------------------------------------------------------

*Copyright (C) 2010, 2011 David Heiko Kolf*

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

<!-- This documentation can be parsed using Markdown to generate HTML.
     The source code is enclosed in a HTML comment so it won't be displayed
     by browsers, but it should be removed from the final HTML file as
     it isn't a valid HTML comment (and wastes space).
  -->

  <!--]==]

-- global dependencies:
local pairs, type, tostring, tonumber, getmetatable, setmetatable =
      pairs, type, tostring, tonumber, getmetatable, setmetatable

local error, require, pcall = error, require, pcall

-- Use math objects
local floor, huge = math.floor, math.huge

-- Use string objects
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
      string.rep, string.gsub, string.sub, string.byte, string.char,
      string.find, string.len, string.format

-- User table object
local concat = assert(table.concat)

if _VERSION == 'Lua 5.1' then
  local function noglobals (s,k,v) error ('global access: ' .. k, 2) end
  setfenv (1, setmetatable ({}, { __index = noglobals, __newindex = noglobals }))
end

local _ENV = nil -- blocking globals in Lua 5.2

local json = { version = 'dkjson 2.1' }

pcall (function()
  -- Enable access to blocked metatables.
  -- Don't worry, this module doesn't change anything in them.
  local debmeta = require 'debug'.getmetatable
  if debmeta then getmetatable = debmeta end
end)

json.null = setmetatable ({}, {
  __tojson = function () return 'null' end
})

-- Function to check if a table is an array.
local function isarray (table)
  local max, count, arraylen = 0, 0, 0
  local MAX_LIMIT = 10
  -- check if parameter is not null
  for key, value in pairs (assert(table)) do
    if key == 'n' and type(value) == 'number' then
      arraylen = value

      if value > max then
        max = value
      end

    else

      if type(key) ~= 'number' or key < 1 or floor(key) ~= key then
        return false
      end

      if key > max then
        max = key
      end

      count = count + 1
    end
  end

  if max > MAX_LIMIT and max > arraylen and max > count * 2 then
    return false -- don't create an array with too many holes
  end
  -- Assert max return
  assert(max)
  return true, max
end

-- UTF-8 escape codes
local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
}


local function escapeutf8 (uchar)
  local value = assert(escapecodes[uchar])

  if value then
    return value
  end

  local byte_1, byte_2, byte_3, byte_4 = strbyte (uchar, 1, 4)
  byte_1, byte_2, byte_3, byte_4 = byte_1 or 0, byte_2 or 0, byte_3 or 0, byte_4 or 0

  -- Replace to UTF-8 codes
  if byte_1 <= 0x7f then
    value = byte_1
  elseif 0xc0 <= byte_1 and byte_1 <= 0xdf and byte_2 >= 0x80 then
    value = (byte_1 - 0xc0) * 0x40 + byte_2 - 0x80
  elseif 0xe0 <= byte_1 and byte_1 <= 0xef and byte_2 >= 0x80 and byte_3 >= 0x80 then
    value = ((byte_1 - 0xe0) * 0x40 + byte_2 - 0x80) * 0x40 + byte_3 - 0x80
  elseif 0xf0 <= byte_1 and byte_1 <= 0xf7 and byte_2 >= 0x80 and byte_3 >= 0x80 and byte_4 >= 0x80 then
    value = (((byte_1 - 0xf0) * 0x40 + byte_2 - 0x80) * 0x40 + byte_3 - 0x80) * 0x40 + byte_4 - 0x80
  else
    return ''
  end

  if value <= 0xffff then
    return strformat ('\\u%.4x', value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ('\\u%.4x\\u%.4x', highsur, lowsur)
  else
    return ''
  end
end

local function fsub (str, pattern, repl)
  -- gsub always builds a new string in a buffer, even when no match
  -- exists. First using find should be more efficient when most strings
  -- don't contain the pattern.
  -- Assert parameters
  assert(str)
  assert(pattern)
  assert(repl)
  if strfind (str, pattern) then
    return gsub (str, pattern, repl)
  else
    return str
  end
end

local function quotestring (value)
  -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js
  -- return string surrounded by quotes
  value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)
  if strfind (value, "[\194\216\220\225\226\239]") then
    value = fsub (value, "\194[\128-\159\173]", escapeutf8)
    value = fsub (value, "\216[\128-\132]", escapeutf8)
    value = fsub (value, "\220\143", escapeutf8)
    value = fsub (value, "\225\158[\180\181]", escapeutf8)
    value = fsub (value, "\226\128[\140-\143\168\175]", escapeutf8)
    value = fsub (value, "\226\129[\160-\175]", escapeutf8)
    value = fsub (value, "\239\187\191", escapeutf8)
    value = fsub (value, "\239\191[\176\191]", escapeutf8)
    return "\"" .. assert(value) .. "\""
  else
    return "\"" .. assert(value) .. "\""
  end
end

json.quotestring = quotestring

-- Add newline to string
local function addnewline2 (level, buffer, buflen)
  assert(level)
  assert(buffer)
  assert(buflen)
  buffer[buflen+1] = '\n'
  buffer[buflen+2] = strrep ('  ', level)
  buflen = buflen + 2
  assert(buflen > 0, 'Buffer length <= 0')
  return buflen
end

-- Add newline to string dealing with identation
function json.addnewline (state)
  if state.indent then
    state.bufferlen = addnewline2 (state.level or 0,
                                   state.buffer,
				   state.bufferlen or #(state.buffer))
  end
end

local encode2 -- forward declaration

-- Add pairs to JSON fields
local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder)
  assert(key, "key not defined")
  local keytype = type (key)

  if keytype ~= 'string' and keytype ~= 'number' then
    return nil, "type '" .. keytype .. "' is not supported as a key by JSON."
  end

  if prev then
    buflen = buflen + 1
    buffer[buflen] = ','
  end

  if indent then
    buflen = addnewline2 (level, buffer, buflen)
  end

  assert(buffer)
  buffer[buflen+1] = quotestring (key)
  buffer[buflen+2] = ':'
  return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder)
end

-- encodes the values into JSON format
encode2 = function (value, indent, level, buffer, buflen, tables, globalorder)
  assert(value)
  local valtype = type (value)
  local valmeta = getmetatable (value)
  valmeta = type (valmeta) == 'table' and valmeta -- only tables
  local valtojson = valmeta and valmeta.__tojson

  if valtojson then

    if tables[value] then
      return nil, 'reference cycle'
    end

    tables[value] = true
    local state = {
        indent = indent, level = level, buffer = buffer,
        bufferlen = buflen, tables = tables, keyorder = globalorder
    }
    local ret, msg = valtojson (value, state)

    if not ret then return nil, msg end

    tables[value] = nil
    buflen = state.bufferlen

    if type (ret) == 'string' then
      buflen = buflen + 1
      buffer[buflen] = ret
    end

  elseif value == nil then
    buflen = buflen + 1
    buffer[buflen] = 'null'

  elseif valtype == 'number' then
    local s

    if value ~= value or value >= huge or -value >= huge then
      -- This is the behaviour of the original JSON implementation.
      s = 'null'
    else
      s = tostring (value)
    end
    buflen = buflen + 1
    buffer[buflen] = s

  elseif valtype == 'boolean' then
    buflen = buflen + 1
    buffer[buflen] = value and 'true' or 'false'

  elseif valtype == 'string' then
    buflen = buflen + 1
    buffer[buflen] = quotestring (value)

  elseif valtype == 'table' then

    if tables[value] then
      return nil, 'reference cycle'
    end

    tables[value] = true
    level = level + 1
    local metatype = valmeta and valmeta.__jsontype
    local isa, n

    if metatype == 'array' then
      isa = true
      n = value.n or #value
    elseif metatype == 'object' then
      isa = false
    else
      isa, n = isarray (value)
    end

    local msg -- forward declaration

    if isa then -- JSON array
      buflen = buflen + 1
      buffer[buflen] = '['
      for i = 1, n do
        buflen, msg = encode2 (value[i], indent, level, buffer, buflen, tables, globalorder)

        if not buflen then return nil, msg end

        if i < n then
          buflen = buflen + 1
          buffer[buflen] = ','
        end
      end

      buflen = buflen + 1
      buffer[buflen] = ']'
    else -- JSON object
      local prev = false
      buflen = buflen + 1
      buffer[buflen] = '{'
      local order = valmeta and valmeta.__jsonorder or globalorder

      if order then
        local used = {}
        n = #order
        for i = 1, n do
          local k = order[i]
          local v = value[k]

          if v then
            used[k] = true
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder)
            prev = true -- add a seperator before the next element
          end

        end

        for k,v in pairs (value) do

          if not used[k] then
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder)

            if not buflen then return nil, msg end

            prev = true -- add a seperator before the next element
          end
        end
      else -- unordered
        for k,v in pairs (value) do
          buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder)

          if not buflen then return nil, msg end

          prev = true -- add a seperator before the next element
        end
      end

      if indent then
        buflen = addnewline2 (level - 1, buffer, buflen)
      end

      buflen = buflen + 1
      buffer[buflen] = "}"
    end
    tables[value] = nil
  else
    assert(valtype)
    return nil, "type '" .. valtype .. "' is not supported by JSON."
  end

  assert(buflen)
  return buflen
end

function json.encode (value, state)
  state = state or {}
  assert(value)
  local oldbuffer = state.buffer
  local buffer = oldbuffer or {}
  local ret, msg = encode2 (value, state.indent, state.level or 0,
                            buffer, state.bufferlen or 0, state.tables or {},
			    state.keyorder)

  if not ret then
    error (msg, 2)
  elseif oldbuffer then
    state.bufferlen = ret
    return true
  else
    assert(buffer)
    return concat (buffer)
  end
end

-- find position of given string
local function loc (str, where)
  local line, pos, linepos = 1, 1, 1
  assert(str)
  assert(where)

  while true do
    pos = strfind (str, '\n', pos, true)

    if pos and pos < where then
      line = line + 1
      linepos = pos
      pos = pos + 1
    else
      -- exit loop
      break
    end
  end

  assert(line)
  assert((where - linepos) > 0)
  return "line " .. line .. ", column " .. (where - linepos)
end

-- report unterminated message
local function unterminated (str, what, where)
  assert(str)
  assert(what)
  assert(where)
  return nil, strlen (str) + 1, "unterminated " .. what .. " at " .. loc (str, where)
end

-- scanwhite Lua function
local function scanwhite (str, pos)
  while true do
    pos = strfind (str, '%S', pos)

    if not pos then return nil end

    if strsub (str, pos, pos + 2) == '\239\187\191' then
      -- UTF-8 Byte Order Mark
      pos = pos + 3
    else
      return pos
    end
  end
end

-- chars to be escaped in encoding
local escapechars = {
  ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", ["b"] = "\b", ["f"] = "\f",
  ["n"] = "\n", ["r"] = "\r", ["t"] = "\t"
}

-- deals with unichar codes
local function unichar (value)
  assert(type(value) == "number", "value must be a number")

  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local function scanstring (str, pos)
  assert(type(pos) == "number")
  assert(str)
  local lastpos = pos + 1
  local buffer, n = {}, 0

  while true do
    local nextpos = strfind (str, "[\"\\]", lastpos)

    if not nextpos then
      return unterminated (str, 'string', pos)
    end

    if nextpos > lastpos then
      n = n + 1
      buffer[n] = strsub (str, lastpos, nextpos - 1)
    end

    if strsub (str, nextpos, nextpos) == "\"" then
      lastpos = nextpos + 1
      break
    else
      local escchar = strsub (str, nextpos + 1, nextpos + 1)
      local value -- forward declaration

      if escchar == 'u' then
        value = tonumber (strsub (str, nextpos + 2, nextpos + 5), 16)

        if value then
          local value2

          if 0xD800 <= value and value <= 0xDBff then
            -- we have the high surrogate of UTF-16. Check if there is a
            -- low surrogate escaped nearby to combine them.
            if strsub (str, nextpos + 6, nextpos + 7) == '\\u' then
              value2 = tonumber (strsub (str, nextpos + 8, nextpos + 11), 16)

              if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                value = (value - 0xD800)  * 0x400 + (value2 - 0xDC00) + 0x10000
              else
                value2 = nil -- in case it was out of range for a low surrogate
              end
            end
          end

          value = value and unichar (value)

          if value then
            if value2 then
              lastpos = nextpos + 12
            else
              lastpos = nextpos + 6
            end
          end
        end
      end

      if not value then
        value = escapechars[escchar] or escchar
        lastpos = nextpos + 2
      end

      n = n + 1
      buffer[n] = value
    end
  end

  assert(lastpos)

  if n == 1 then
    assert(buffer[1])
    return buffer[1], lastpos
  elseif n > 1 then
    assert(buffer)
    return concat (buffer), lastpos
  else
    return '', lastpos
  end
end

local scanvalue -- forward declaration

local function scantable (what, closechar, str, startpos, nullval, objectmeta, arraymeta)
  assert(str)
  local len = strlen (str)
  local tbl, n = {}, 0
  local pos = startpos + 1
  while true do
    pos = scanwhite (str, pos)

    if not pos then return unterminated (str, what, startpos) end

    local char = strsub (str, pos, pos)

    if char == closechar then
      assert(tbl)
      assert(pos)
      return tbl, pos + 1
    end

    local scan1, err
    scan1, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)

    if err then return nil, pos, err end

    pos = scanwhite (str, pos)

    if not pos then return unterminated (str, what, startpos) end

    char = strsub (str, pos, pos)

    if char == ':' then

      if scan1 == nil then
	assert(pos)
        return nil, pos, "cannot use nil as table index (at " .. loc (str, pos) .. ")"
      end

      pos = scanwhite (str, pos + 1)

      if not pos then return unterminated (str, what, startpos) end

      local scan2
      scan2, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)

      if err then return nil, pos, err end

      tbl[scan1] = scan2
      pos = scanwhite (str, pos)

      if not pos then return unterminated (str, what, startpos) end

      char = strsub (str, pos, pos)
    else
      n = n + 1
      tbl[n] = scan1
    end

    if char == ',' then
      pos = pos + 1
    end

  end
end

scanvalue = function (str, pos, nullval, objectmeta, arraymeta)
  pos = pos or 1
  assert(str)
  pos = scanwhite (str, pos)

  if not pos then
    return nil, strlen (str) + 1, 'no valid JSON value (reached the end)'
  end

  local char = strsub (str, pos, pos)

  if char == '{' then
    return scantable ('object', '}', str, pos, nullval, objectmeta, arraymeta)
  elseif char == '[' then
    return scantable ('array', ']', str, pos, nullval, objectmeta, arraymeta)
  elseif char == '\"' then
    return scanstring (str, pos)
  else
    local pos_start, pos_end = strfind (str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)

    if pos_start then
      local number = tonumber (strsub (str, pos_start, pos_end))

      if number then
        return number, pos_end + 1
      end

    end

    pos_start, pos_end = strfind (str, "^%a%w*", pos)

    if pos_start then
      local name = strsub (str, pos_start, pos_end)

      if name == 'true' then
        return true, pos_end + 1
      elseif name == 'false' then
        return false, pos_end + 1
      elseif name == 'null' then
        return nullval, pos_end + 1
      end
    end
    return nil, pos, 'no valid JSON value at ' .. loc (str, pos)
  end
end

function json.decode (str, pos, nullval, objectmeta, arraymeta)
  objectmeta = objectmeta or {__jsontype = 'object'}
  arraymeta = arraymeta or {__jsontype = 'array'}
  assert(str)
  assert(pos)
  assert(objectmeta)
  assert(arraymeta)
  return scanvalue (str, pos, nullval, objectmeta, arraymeta)
end

function json.use_lpeg ()
  local lpeg = require ('lpeg')
  assert(lpeg)
  local pegmatch = lpeg.match
  local P, S, R, V = lpeg.P, lpeg.S, lpeg.R, lpeg.V

  local SpecialChars = (R"\0\31" + S"\"\\\127" +
    P"\194" * (R"\128\159" + P"\173") +
    P"\216" * R"\128\132" +
    P"\220\132" +
    P"\225\158" * S"\180\181" +
    P"\226\128" * (R"\140\143" + S"\168\175") +
    P"\226\129" * R"\160\175" +
    P"\239\187\191" +
    P"\229\191" + R"\176\191") / escapeutf8

  local QuoteStr = lpeg.Cs (lpeg.Cc "\"" * (SpecialChars + 1)^0 * lpeg.Cc "\"")

  quotestring = function (str)
    assert(str)
    return pegmatch (QuoteStr, str)
  end
  json.quotestring = quotestring

  local function ErrorCall (str, pos, msg, state)

    if not state.msg then
      state.msg = msg .. ' at ' .. loc (str, pos)
      state.pos = pos
    end

    return false
  end

  local function Err (msg)
    return lpeg.Cmt (lpeg.Cc (msg) * lpeg.Carg (2), ErrorCall)
  end

  local Space = (S" \n\r\t" + P"\239\187\191")^0

  local PlainChar = 1 - S"\"\\\n\r"
  local EscapeSequence = (P"\\" * lpeg.C (S"\"\\/bfnrt" + Err "unsupported escape sequence")) / escapechars
  local HexDigit = R("09", "af", "AF")
  local function UTF16Surrogate (match, pos, high, low)
    high, low = tonumber (high, 16), tonumber (low, 16)

    if 0xD800 <= high and high <= 0xDBff and 0xDC00 <= low and low <= 0xDFFF then
      return true, unichar ((high - 0xD800)  * 0x400 + (low - 0xDC00) + 0x10000)
    else
      return false
    end
  end

  local function UTF16BMP (hex)
    return unichar (tonumber (hex, 16))
  end

  local U16Sequence = (P'\\u' * lpeg.C (HexDigit * HexDigit * HexDigit * HexDigit))
  local UnicodeEscape = lpeg.Cmt (U16Sequence * U16Sequence, UTF16Surrogate) + U16Sequence/UTF16BMP
  local Char = UnicodeEscape + EscapeSequence + PlainChar
  local String = P"\"" * lpeg.Cs (Char ^ 0) * (P"\"" + Err "unterminated string")
  local Integer = P"-"^(-1) * (P"0" + (R"19" * R"09"^0))
  local Fractal = P"." * R"09"^0
  local Exponent = (S"eE") * (S"+-")^(-1) * R"09"^1
  local Number = (Integer * Fractal^(-1) * Exponent^(-1))/tonumber
  local Constant = P"true" * lpeg.Cc (true) + P"false" * lpeg.Cc (false) + P"null" * lpeg.Carg (1)
  local SimpleValue = Number + String + Constant
  local ArrayContent, ObjectContent

  -- The functions parsearray and parseobject parse only a single value/pair
  -- at a time and store them directly to avoid hitting the LPeg limits.
  local function parsearray (str, pos, nullval, state)
    local obj, cont
    local npos
    local t, nt = {}, 0

    repeat
      obj, cont, npos = pegmatch (ArrayContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      nt = nt + 1
      t[nt] = obj
    until cont == 'last'

    assert(pos)
    assert(t)
    return pos, t-- setmetatable (t, state.objectmeta)
  end

  local function parseobject (str, pos, nullval, state)
    local obj, key, cont
    local npos
    local t = {}

    repeat
      key, obj, cont, npos = pegmatch (ObjectContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      t[key] = obj
    until cont == 'last'

    assert(pos)
    assert(t)
    return pos, t-- setmetatable (t, state.objectmeta)
  end

  local Array = P"[" * lpeg.Cmt (g.Carg(1) * lpeg.Carg(2), parsearray) * Space * (P"]" + Err "']' expected")
  local Object = P"{" * lpeg.Cmt (g.Carg(1) * lpeg.Carg(2), parseobject) * Space * (P"}" + Err "'}' expected")
  local Value = Space * (Array + Object + SimpleValue)
  local ExpectedValue = Value + Space * Err "value expected"
  ArrayContent = Value * Space * (P',' * lpeg.Cc'cont' + lpeg.Cc'last') * lpeg.Cp()
  local Pair = lpeg.Cg (Space * String * Space * (P":" + Err "colon expected") * ExpectedValue)
  ObjectContent = Pair * Space * (P',' * lpeg.Cc'cont' + lpeg.Cc'last') * lpeg.Cp()
  local DecodeValue = ExpectedValue * lpeg.Cp ()

  function json.decode (str, pos, nullval, objectmeta, arraymeta)
    local state = {
      objectmeta = objectmeta or {__jsontype = 'object'},
      arraymeta = arraymeta or {__jsontype = 'array'}
    }
    local obj, retpos = pegmatch (DecodeValue, str, pos, nullval, state)

    if state.msg then
      assert(state.pos)
      assert(state.msg)
      return nil, state.pos, state.msg
    else
      assert(obj)
      assert(retpos)
      return obj, retpos
    end
  end

  -- use this function only once:
  json.use_lpeg = function () return json end
  json.using_lpeg = true

  assert(json)
  return json -- so you can get the module using json = require "dkjson".use_lpeg()
end

if always_try_using_lpeg then
  pcall (json.use_lpeg)
end

return json
