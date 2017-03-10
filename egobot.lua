local _require = loadstring("return require")() -- Get the real require back :<
local sql = require("sqlite3")
local start_date = os.date()
local fs = require('fs')
local discordia = require('discordia')
local client = discordia.Client()
local weblit = require('weblit')
local config = dofile('./config.lua')
local token = args[2]

--[[
   Helper function
]]
local log = require('logger')
local util = {}
local shared = {db = sql.open("egobot.db")}

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

local commands = setmetatable({}, {__index = 
function(t, k)
   return {call =
      function(msg, cmd)
         log('Unknown command \''.. cmd ..'\'', log.Warning, 'core')
      end, enabled = true}
end})

for _, fn in ipairs(fs.readdirSync('.')) do
   if fn:match('^cmd_([^.]+)%.lua$') then
      local fcmd, err = loadfile(fn)
      if not fcmd then
	 log('Error loading '..err, log.Error, 'core')
	 if config.exit_on_load_error then os.exit() end
      else
	 local cmds = {fcmd(require, util, shared, client)}
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
client:run(token)
