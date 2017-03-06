local start_date = os.date()
local fs = require('fs')
local discordia = require('discordia')
local client = discordia.Client()

local config, colors, ascii_emotes = dofile('./config.lua')
setmetatable(ascii_emotes or {}, {__index = function (t, k) return k end})
setmetatable(colors or {}, {__index = function (t, k) return '' end})


--[[
   Helper function
]]
local log = require('logger')
local util = {}
local shared = {}

function util.code(c, l)
   return '```'..(l or '')..'\n'..c..'```'
end

function util.printf(...)
   return print(string.format(...))
end

function util.eval_math(expr)
   if not expr or #expr == 0 then return '' end -- Check for no arg or empty arg
   local ft = "return (" .. expr .. ")" -- Make text function

   local sb = setmetatable({}, {__index = math}) -- Create sandbox with math functions as its index (props to Siapran)
   local f, syntax_error = load(ft, '{sandbox.math}', 't', sb) -- Load text function
   if not f then return false, syntax_error end -- Test for syntax error and output it if any

   local status, res = pcall(f) -- safe (catch) call function
   if not status then return false, res end -- return with error if any
   return true, tostring(res) -- return result
end


--[[
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

]]

local commands = setmetatable({}, {__index = 
function(t, k)
   return {call =
      function(msg, cmd)
         log('Unknown command \''.. cmd ..'\'', log.Warning, 'core')
      end, enabled = true}
end})

for _, fn in ipairs(fs.readdirSync('.')) do
   if fn:match('^cmd_([^.]+)%.lua$') then
      local cmds = {loadfile(fn)(require, util, shared, client)}
      for _, cmd in ipairs(cmds) do
         cmd.filename = fn
         cmd.enabled = true
         if not commands[cmd.name].name then
            commands[cmd.name] = cmd
            log('Registered command \''.. cmd.name ..'\'', log.Info, 'core')
         else
            log('Command \''.. cmd.name ..'\' from '..fn..' is already registered', log.Warning, 'core')
         end
      end
   end
end
   
--[[
   Discordia events and main loop
]]

client:on('ready',
	  function()
	     args[2] = "Why the f**k would you print args ?" -- Courtesy of Siapran
	     log(string.format('Logged in as %s#%d (%d)', client.user.username, client.user.discriminator, client.user.id), log.Info, 'core')
	  end
)

client:on('messageCreate',
	  function(msg)
	     -- exit early if the author is the *NOT* same as the client
	     if msg.author ~= client.user then return end
             -- exit if message isn't a command'
	     if not msg.content:match('^'..config.prefix..'([^%s]+)%s*(.*)$') then return end

	     local cmd, arg = msg.content:match('^'..config.prefix..'(%S+)%s*(.*)$')
	     
             if commands[cmd].enabled then
                local status, res = pcall(commands[cmd].call, msg, cmd, arg, config)
                if not status then log("Error occured while running command '"..cmd.."': "..tostring(res), log.Error, 'core') end
             end
	  end
)

client:on('warning', function(warn) end)

if not args[2] then print('Usage: '..args[1]..' <DISCORD TOKEN>') os.exit() end
client:run(args[2])
