local _, util = ...
local log = require('logger')

local _RUN = {
   name = 'run',
   call = 
   function(msg, cmd, arg, config)
      if #arg == 0 then return end
      
      msg.content = config.prefix..cmd..' `'..arg..'`'
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
   usage = '${prefix}${cmd} <command line>',
   description = 'This executes a command line',
   author = 'LazyShpee'
}

local _PIPE = {
   name = 'pipe',
   call = function(msg, cmd, arg, config)
      if #arg == 0 then return end
      local cmdl, input = arg:match('^`(.-)` ```[^\n]-\n(.*)```$')
      local fd = io.open("./tmp_pipe", "w")
      fd:write(input)
      fd:close()
      local fp = io.popen("cat ./tmp_pipe | "..cmdl, "r")
      output = fp:read("*a")
      fp:close()
      log('Piped '..#input..' char(s) in `'..cmdl..'`')

      if #output <= 1990 then
         msg:reply(util.code(output))
      else
         output = output:sub(1, 1980)
         msg:reply(util.code(output)..'`[SNIP]`')
      end
   end,
   usage = '${prefix}${cmd} `command line` ```input data```',
   description = 'This execute a command and feeds it some input data',
   author = 'LazyShpee'
}

return _RUN, _PIPE
