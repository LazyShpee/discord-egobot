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

local sandbox = {}

local function reset()
   sandbox = {}
   setmetatable(sandbox, {__index = _G})
end

reset()

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
      sandbox.msg = m
      sandbox._C = true  -- Format output in markdown block
      sandbox._S = false -- Silent
      sandbox._O = true  -- Show result output
      sandbox._D = false -- Delete eval message
      sandbox.reset = reset
      sandbox.print = function(...) table.insert(output, printLine(...)) end
      sandbox.p = function(...) table.insert(output, prettyLine(...)) end
      sandbox.client = client
      sandbox.util = util
            
      local fn, syntax = load(tf, '{sandbox.'..c..'}', 't', sandbox)
      if not fn then return m:reply(util.code(syntax)) end
      local success, runtime = pcall(fn)
      if not success then return m:reply(util.code(runtime)) end

      if #output == 0 then if sandbox._S then return end return m:reply(util.code('Execution completed.')) end
      output = table.concat(output, '\n')
      if sandbox._O then
	 if #output <= 1990 then
	    if sandbox._C then
	       m:reply(util.code(output))
	    else
	       m:reply(output)
	    end
	 elseif not sandbox._S then
	    output = output:sub(1, 1980)
	    if sandbox._C then
	       m:reply(util.code(output)..'`[SNIP]`')
	    else
	       m:reply(output..'`[SNIP]`')
	    end
	 end
      end
      if sandbox._D then
	 m:delete()
      end
   end
}

return _EVAL
