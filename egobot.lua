local start_date = os.date()
local discordia = require('discordia')
local querystring = require("querystring")
local client = discordia.Client()

local md5 = require('md5')

local config, colors, ascii_emotes = dofile('./config.lua')
setmetatable(ascii_emotes or {}, {__index = function (t, k) return k end})
setmetatable(colors or {}, {__index = function (t, k) return '' end})

--[[
   Helper function
]]

local function log(m, e)
   e = e or ' '
   local c = config.error_levels[e] and '\27['..config.error_levels[e]..'m' or ''
   print(c..'['..e:upper()..']'..os.date('[%D %R] ')..m..'\27[0m')
end

local function code(c, l)
   return '```'..(l or '')..'\n'..c..'```'
end

local function printf(...)
   return print(string.format(...))
end

local backlog = ''

--[[
   Command definition
   The are invoked with the following arguments:
     - message object
     - command without prefix (useful for dynamic debugging)
     - whole arguments as one string
     - client object
]]

local cmds = setmetatable({}, {__index = function(t, k) return function(m, c, a, cl) log("Command "..c.." not found.", 'w') m:delete() end end })

cmds.quote = function(m, c, a, cl)
   local id, pattern, reply = {}, '.*', ''
   a = a..' '
   a:gsub('(%d+) ',
   function(m)
      table.insert(id, m)
      return ''
   end):gsub('/([^/]+)/ ',
   function(m)
      pattern = m
      return ''
   end):gsub('(.*) ',
   function(m)
      reply = m
      return ''
   end)

   local channel = m.channel
   if #id >= 2 then channel = client:getChannel("id", id[2]) end
   if #id == 0 then return end -- Requires at least one id
   if channel then
      for msg in channel:getMessageHistoryAround({_id = id[1]}, 1) do
	 if msg and msg.id == id[1] then

	    local mq = table.concat({msg.content:match(pattern)}, ' ')
	    if #mq == 0 then break end

	    local resp = {embed = {
			     description = mq,
			     color = 6673764,
			     author = {
				name = msg.author.username,
				icon_url = msg.author.avatarUrl
			     },
			     timestamp = os.date('!%Y-%m-%dT%H:%M:%S', msg.createdAt)
			 }}
	    
	    -- Courtesy of Siapran
	    if m.channel ~= channel then
	       if m.guild ~= channel.guild then
		  resp.embed.footer = {
		     text = "On " .. channel.guild.name .. " | #" .. channel.name,
		     icon_url = channel.guild.iconUrl,
		  }
	       else
		  resp.embed.footer = {
		     text = "On #" .. channel.name,
		  }
	       end
	    end

	    m:reply(resp)
	    if reply and #reply > 0 then m:reply(reply) end
	    log('Quoted '..msg.author.username..' ['..id[1]..'] '..pattern)
	    break
	 end
      end
   end
   m:delete()
end

-- Evaluates a math expression written in lua
local function eval_math(expr)
   if not expr or #expr == 0 then return '' end -- Check for no arg or empty arg
   local ft = "return (" .. expr .. ")" -- Make text function

   local sb = setmetatable({}, {__index = math}) -- Create sandbox with math functions as its index (props to Siapran)
   local f, syntax_error = load(ft, '{sandbox.math}', 't', sb) -- Load text function
   if not f then return false, syntax_error end -- Test for syntax error and output it if any

   local status, res = pcall(f) -- safe (catch) call function
   if not status then return false, res end -- return with error if any
   return true, tostring(res) -- return result
end

cmds.math = function (m, c, a, cl)
   local status, res = eval_math(a)
   if status then
      m.content = code(a..'=\n'..tostring(res)) -- replace with result
   else
      m.content = code(tostring(res)) -- replace with error
   end
end

cmds.f = function (m, c, a, cl)
   if not a or #a == 0 then return end
   local res = a:gsub('{([^}]+)}',
		      function(e)
			 local s, r = eval_math(e)
			 return s and e..'='..tostring(r) or e..'='..'ERR'
		      end
   ):gsub('<([^>]+)>',
	  function (e)
	     return ascii_emotes[e]
	  end
	 )
   m.content = res
end

cmds.run = function(m, c, a, cl)
   if #a == 0 then return end
   m.content = config.prefix..c..' `'..a..'`'
   local file = assert(io.popen(a, 'r'))
   local output = file:read('*all')
   file:close()
   log('Ran `'..a..'`')

   backlog = output -- Save output to backlog (in case its too big)
   if #output <= 1990 then
      m:reply(code(output))
   else
      output = output:sub(1, 1980)
      m:reply(code(output)..'`[SNIP]`')
   end
end

cmds.pipe = function(m, c, a, cl)
   if #a == 0 then return end
   local cmd, input = a:match('^`([^`]-)` ```[^\n]-\n(.*)```$')
   local fp = io.popen(cmd.." > ./unique", "w")
   fp:write(input)
   fp:close()
   fp = io.open("./unique", "r")
   output = fp:read("*a")
   fp:close()
   log('Pipe '..#input..' char(s) in `'..cmd..'`')

   backlog = output -- Save output to backlog (in case its too big)
   if #output <= 1990 then
      m:reply(code(output))
   else
      output = output:sub(1, 1980)
      m:reply(code(output)..'`[SNIP]`')
   end
end

--courtesy of Siapran
local function printLine(...)
   local ret = {}
   for i = 1, select('#', ...) do
      local arg = tostring(select(i, ...))
      table.insert(ret, arg)
   end
   return table.concat(ret, '\t')
end

--courtesy of Siapran
local function prettyLine(...)
   local ret = {}
   for i = 1, select('#', ...) do
      local arg = pp.strip(pp.dump(select(i, ...)))
      table.insert(ret, arg)
   end
   return table.concat(ret, '\t')
end

cmds.eval = function(m, c, a, cl)
   if #a == 0 then return end
   local tf

   if     a:match("^```[^\n]-\n(.*)```$") then	tf = a:match("^```[^\n]-\n(.*)```$")
   elseif a:match("^`(.*)`$") then		tf = a:match("^`(.*)`$")
   else						tf = a
   end

   local output = {}
   local sandbox = setmetatable({}, {__index = _G})
   sandbox.msg = m
   sandbox.client = cl
   sandbox.backlog = backlog
   sandbox.print = function(...) table.insert(output, printLine(...)) end
   sandbox.p = function(...) table.insert(output, prettyLine(...)) end

   local fn, syntax = load(tf, '{sandbox.'..c..'}', 't', sandbox)
   if not fn then return m:reply(code(syntax)) end
   local success, runtime = pcall(fn)
   if not success then return m:reply(code(runtime)) end

   if #output == 0 then return m:reply(code('Execution completed.')) end
   output = table.concat(output, '\n')
   if #output <= 1990 then
      m:reply(code(output))
   else
      output = output:sub(1, 1980)
      m:reply(code(output)..'`[SNIP]`')
   end
end

cmds.md5 = function(m, c, a, cl)
   if #a == 0 then return end
   m.content = '`md5("'..a..'") = '..md5.sumhexa(a)..'`'
end

--[[
   Discordia events and main loop
]]

client:on('ready',
	  function()
	     args[2] = "Why the f**k would you print args ?" -- Courtesy of Siapran
	     log(string.format('Logged in as %s#%d (%d)', client.user.username, client.user.discriminator, client.user.id), 'i')
	  end
)

client:on('messageCreate',
	  function(message)
	     -- exit early if the author is the *NOT* same as the client
	     if message.author ~= client.user then return end
	     if not message.content:match('^'..config.prefix..'([^%s]+)%s*(.*)$') then return end
	     local cmd, arg = message.content:match('^'..config.prefix..'([^%s]+)%s*(.*)$')
	     
	     local status, res = pcall(cmds[cmd], message, cmd, arg, client)
	     if not status then log("Error occured while running command '"..cmd.."': "..tostring(res)) end
	  end
)

client:on('warning',
	  function(warn)
	     --l(warn, 'w')
	  end
)

if not args[2] then print ('Usage: '..args[1]..' <DISCORD TOKEN>') os.exit() end
client:run(args[2])
