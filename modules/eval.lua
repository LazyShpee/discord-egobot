local req, util, _, client = ... -- Getting the luvit custom require
local log = require('utils.logger')
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
  call = function(m, c, a, o)
    if #a == 0 then return end
    --print(pp.strip(pp.dump(o)))
    local tf

    if     a:match("^```[^\n]-\n(.*)```$") then       tf = a:match("^```[^\n]-\n(.*)```$")
    elseif a:match("^`(.*)`$") then                   tf = a:match("^`(.*)`$")
    else                                              tf = a
    end

    local output = {}
    if not o.persist then reset() end
    sandbox.msg = m
    sandbox._C = o.code  -- Format output in markdown block
    sandbox._S = o.silent -- Silent
    sandbox._O = o.ouput  -- Show result output
    sandbox._D = o.delete -- Delete eval message
    sandbox._E = o.error  -- output error log
    sandbox.reset = reset
    sandbox.print = function(...) table.insert(output, printLine(...)) end
    sandbox.p = function(...) table.insert(output, prettyLine(...)) end
    sandbox.client = client
    sandbox.util = util
            
    local fn, syntax = load(tf, '{sandbox.'..c..'}', 't', sandbox)
    if not fn then return m:reply(util.code(syntax)) end
    local success, runtime = pcall(fn)
    if not success then if o.error then return m:reply(util.code(runtime)) else return end end

    if #output == 0 then
      if not sandbox._S then m:reply(util.code('Execution completed.')) end
    else
      output = table.concat(output, '\n')
      if not sandbox._S or sandbox._O then
        if #output <= 1990 then
          if sandbox._C then
            m:reply(util.code(output))
          else
            m:reply(output)
          end
        else
          output = output:sub(1, 1980)
          if sandbox._C then
            m:reply(util.code(output)..'`[SNIP]`')
          else
            m:reply(output..'`[SNIP]`')
          end
        end
      end
    end
    if sandbox._D then
      m:delete()
    end
  end,
  usage = '<lua code>|`<lua code>`|```<lua code>```',
  description = [[Evalutes a piece of Lua code in a semi persistent sandbox
Sandbox Variable:
  - _C, true, show ouput in markdown block
  - _S, false, hide 'Execution completed.' when done and no output
  - _O, true, show the print output
  - _D, false, delete command message
  - reset(), resets the sandbox global variables
  - msg, the emmited command message object
  - client, egobot client object]],
  author = 'LazyShpee',
  display_name = 'Lua Eval',
  options = {
    silent = { type = 'toggle', default = false, label = 'Silence any ouput' },
    error = { type = 'toggle', default = true, label = 'Show error output' },
    delete = { type = 'toggle', default = false, label = 'Delete command message' },
    ouput = { type = 'toggle', default = true, label = 'Show output' },
    code = { type = 'toggle', default = true, label = 'Format output in command block' },
    persist = { type = 'toggle', default = true, label = 'Persistent run environment' },
--    add = { type = 'editor', default = '', label = 'Code to execute on reset()', lang = 'lua' }
  }
}

return _EVAL
