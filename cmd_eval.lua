local req, util, _, client = ... -- Getting the luvit custom require
local log = require('logger')
local pp = req('pretty-print')

--courtesy of Siapran
local function printLine(...)
   local ret = {}
   for _, v in ipairs({...}) do
      table.insert(ret, tostring(v))
   end
   return table.concat(ret, '\t')
end

local function prettyLine(...)
   local ret = {}
   for _, v in ipairs({...}) do
      v = pp.strip(pp.dump(v))
      table.insert(ret, tostring(v))
   end
   return table.concat(ret, '\t')
end

local _EVAL = {
   name = 'eval',
   usage = '${prefix}${cmd} <lua code>|`<lua code>`|```<lua code>```',
   author = 'LazyShpee',
   call = function(m, c, a)
      if #a == 0 then return end
      local tf

      if     a:match("^```[^\n]-\n(.*)```$") then       tf = a:match("^```[^\n]-\n(.*)```$")
      elseif a:match("^`(.*)`$") then                   tf = a:match("^`(.*)`$")
      else                                              tf = a
      end

      local output = {}
      local sandbox = setmetatable({}, {__index = _G})
      sandbox.msg = m
      sandbox.client = client
      sandbox.print = function(...) table.insert(output, printLine(...)) end
      sandbox.p = function(...) table.insert(output, prettyLine(...)) end
      

      local fn, syntax = load(tf, '{sandbox.'..c..'}', 't', sandbox)
      if not fn then return m:reply(util.code(syntax)) end
      local success, runtime = pcall(fn)
      if not success then return m:reply(util.code(runtime)) end

      if #output == 0 then return m:reply(code('Execution completed.')) end
      output = table.concat(output, '\n')
      if #output <= 1990 then
         m:reply(util.code(output))
      else
         output = output:sub(1, 1980)
         m:reply(util.code(output)..'`[SNIP]`')
      end
   end
}

return _EVAL