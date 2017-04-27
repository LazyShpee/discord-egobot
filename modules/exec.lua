local _, util = ...
local log = require('utils.logger')

local _RUN = {
  name = 'run',
  call = 
  function(msg, cmd, arg, config)
    if #arg == 0 then return end
     
    local file = assert(io.popen(arg, 'r'))
    local output = file:read('*all')
    file:close()
    log('Ran `'..arg..'`', nil, 'run')

    if #output <= 1990 then
      msg:reply(util.code(output))
    else
      output = output:sub(1, 1980)
      msg:reply(util.code(output)..'`[SNIP]`')
    end
  end,
  usage = '<command line>',
  description = 'This executes a command line',
  author = 'LazyShpee'
}

-- local _PIPE = {
--    name = 'pipe',
--    call = function(msg, cmd, arg, config)
--       if #arg == 0 then return end
--       local cmdl, input = arg:match('^`(.-)` ```[^\n]-\n(.*)```$')
--       -- local fd = io.open("./tmp_pipe", "w")
--       -- fd:write(input)
--       -- fd:close()
--       -- local fp = io.popen("cat ./tmp_pipe | "..cmdl, "r")
--       -- output = fp:read("*all")
--       -- fp:close()
--       local output = splat_popen(input, cmdl)
--       log('Piped '..#input..' char(s) in `'..cmdl..'`')
--       if #output <= 1990 then
--          msg:reply(util.code(output))
--       else
--          output = output:sub(1, 1980)
--          msg:reply(util.code(output)..'`[SNIP]`')
--       end
--    end,
--    usage = '`command line` ```input data```',
--    description = 'This execute a command and feeds it some input data',
--    author = 'LazyShpee'
-- }

local _STORE = {
  name = 'sto',
  call = function(msg, cmd, arg, config)
    if #arg == 0 then return end
    local name, input = arg:match('^(.-) ?```[^\n]-\n(.*)```$')
    if #name == 0 then name = "default" end
    local fd = io.open("./sto_"..name, "w")
    fd:write(input)
    fd:close()
  end,
  usage = '[name] ```data```',
  display_name = 'Store Data',
  author = 'LazyShpee',
  description = [[Stores `data` to file `sto_$name` ($name defaults to 'default')
Useful to be use with the run module (ie: store a perl script and execute it)
]]
}

return _RUN, _STORE
