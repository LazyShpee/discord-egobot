local _require = loadstring('return require')() -- Get the real require back :<
local sql = require('sqlite3')
local fs = require('fs')
local discordia = require('discordia')
local client = discordia.Client()
local http = require('http')
local fs = require('fs')
local config = dofile('./config.lua')

local token, webpass, http_server = args[2], args[3]
local start_date = os.date()
local logfile = io.open('logs.log', 'a')

--[[
   Helper function
]]
local log = require('utils.logger')
local util = {}
local shared = {db = sql.open("egobot.db")}
local db = shared.db

function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function string:mmatch(pattern)
  local ma = false
  pattern:gsub('([^|]+)', function(m)
    if m == self then
      ma = true
    end
  end)
  return ma
end

function util.hash_size(tbl)
  local c = 0
  for i in pairs(tbl) do
    c = c + 1
  end
  return c
end

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
   Module loader
]]

local commands

db "CREATE TABLE IF NOT EXISTS modules(name TEXT, state TEXT)"
db "CREATE TABLE IF NOT EXISTS modules_config(module TEXT, name TEXT, type TEXT, value TEXT)"

function getValue(val, typename)
  val = tostring(val)
  if typename:mmatch("toggle|boolean") then
    return val == "true"
  elseif typename:mmatch("string|multiline") then
    return tostring(val)
  elseif typename:mmatch("int|number") then
    return tonumber(val)
  elseif typename:mmatch("color") then
    return val:gsub("^#", '')
  end
  return val
end

function getModuleOptions(name)
  local opt = {}
  if not name then return opt end
  local r = db:exec('SELECT * FROM modules_config WHERE module = "'..name..'"')
  if r and #r > 0 then
    for i=1,#r.name do
      opt[r.name[i]] = getValue(r.value[i], r.type[i])
    end
  end
  return opt
end

commands = setmetatable({}, {__index = 
function(t, k)
  return {call =
    function(msg, cmd)
      log('Unknown command \''.. cmd ..'\'', log.Warning, 'core')
    end, enabled = true}
end})


local modules_dir = 'modules/'

for _, fn in ipairs(fs.readdirSync(modules_dir)) do
  if fn:match('^([^.]+)%.lua$') then
    local fcmd, err = loadfile(modules_dir..fn)
    if not fcmd then
      log('Error loading '..err, log.Error, 'core')
      if config.exit_on_load_error then os.exit() end
    else
      local cmds = {fcmd(require, util, shared, client)}
      for _, cmd in ipairs(cmds) do
        if not commands[cmd.name].name then
          commands[cmd.name] = cmd
          --log('Registered command \''.. cmd.name ..'\'', log.Info, 'core')
          cmd.filename = fn

          local r = db:exec('SELECT * FROM modules WHERE name = "'..(cmd.name)..'"')
          if not r or #r == 0 then
            cmd.enabled = true
            db('INSERT INTO modules VALUES("'.. cmd.name ..'", "true")')
          else
            cmd.enabled = (r.state[1] == 'true')
          end
          
          if cmd.options then
            for opt, t in pairs(cmd.options) do
              r = db:exec('SELECT * FROM modules_config WHERE name = "'..(opt)..'" AND module = "'..(cmd.name)..'"')
              if not r or #r == 0 then -- Options no declared
                db('INSERT INTO modules_config VALUES("'..(cmd.name)..'", "'..(opt)..'", "'..(t.type)..'", "'..(tostring(t.default):gsub('"', '""'))..'")')
              end
            end
          end
          
          if cmd.enabled and cmd.on_option_update then
            cmd.on_option_update(getModuleOptions(cmd.name))
          end
          
        else
          log('Command \''.. cmd.name ..'\' from '..fn..' is already registered', log.Warning, 'core')
        end
      end
    end
  end
end

log('Loaded '..util.hash_size(commands)..' module(s).', log.Info, 'core')

--[[
   Discordia events and main loop
]]

local http_started = false

client:on('ready',
  function()
    args[2] = nil -- "Why the f**k would you print args ?" -- Courtesy of Siapran
    args[3] = nil
    log(string.format('Logged in as %s#%d (%d)', client.user.username, client.user.discriminator, client.user.id), log.Info, 'core')
    if http_server and not http_started then
      http_started = true
      http_server:listen(1234)
      log('Listening on port 1234')
    end
  end)

client:on('messageUpdate', function (msg)
    if msg.channel.isPrivate then
      io.stderr:write('[E][PRIVAMSG]['..os.time()..':'..os.date()..']['..msg.author.id..':'..msg.id..']'..
                    '['..msg.author.username..'#'..msg.author.discriminator..']:'..msg.content..'\n')
    else
      io.stderr:write('[E][GUILDMSG]['..os.time()..':'..os.date()..']['..msg.guild.id..':'..msg.channel.id..':'..msg.author.id..':'..msg.id..']'..
                    '['..msg.guild.name..':'..msg.channel.name..':'..msg.author.username..'#'..msg.author.discriminator..']:'..msg.content..'\n')
    end
end)


client:on('messageDelete', function (msg)
    if msg.channel.isPrivate then
      io.stderr:write('[D][PRIVAMSG]['..os.time()..':'..os.date()..']['..msg.author.id..':'..msg.id..']'..
                    '['..msg.author.username..'#'..msg.author.discriminator..']:'..msg.content..'\n')
    else
      io.stderr:write('[D][GUILDMSG]['..os.time()..':'..os.date()..']['..msg.guild.id..':'..msg.channel.id..':'..msg.author.id..':'..msg.id..']'..
                    '['..msg.guild.name..':'..msg.channel.name..':'..msg.author.username..'#'..msg.author.discriminator..']:'..msg.content..'\n')
    end
end)


  
client:on('messageCreate',
  function(msg)
    if msg.channel.isPrivate then
      io.stderr:write('[C][PRIVAMSG]['..os.time()..':'..os.date()..']['..msg.author.id..':'..msg.id..']'..
                    '['..msg.author.username..'#'..msg.author.discriminator..']:'..msg.content..'\n')
    else
      io.stderr:write('[C][GUILDMSG]['..os.time()..':'..os.date()..']['..msg.guild.id..':'..msg.channel.id..':'..msg.author.id..':'..msg.id..']'..
                    '['..msg.guild.name..':'..msg.channel.name..':'..msg.author.username..'#'..msg.author.discriminator..']:'..msg.content..'\n')
    end
  
    -- exit early if the author is the *NOT* same as the client
    if msg.author ~= client.user then return end
    -- exit if message isn't a command'
    if not msg.content:match('^'..config.prefix..'([^%s]+)%s*(.*)$') then return end

    local cmd, arg = msg.content:match('^'..config.prefix..'(%S+)%s*(.*)$')
	     
    if commands[cmd].enabled then
      local status, res = pcall(commands[cmd].call, msg, cmd, arg, getModuleOptions(cmd))
      if not status then log("Error occured while running command '"..cmd.."': "..tostring(res), log.Error, 'core') end
    end
  end)

client:on('warning', function(warn) end)

if not args[2] then print('Usage: '..args[1]..' <DISCORD TOKEN>') os.exit() end
client:run(token)

--[[
   Web UI
]]

if webpass and #webpass > 0 then
  local mimes = require('utils.mime_types')
  local http = require('http')
  local url = require('url')
  local fs = require('fs')
  local Response = require('http').ServerResponse
  local json = require('json')

  function getType(path)
    return mimes[path:lower():match("[^.]*$")] or mimes.default
  end

   -- Monkey patch in a helper
  function Response:notFound(reason)
    self:writeHead(404,
      {
        ["Content-Type"] = "text/plain",
	["Content-Length"] = #reason
      })
    self:write(reason)
  end

  -- Monkey patch in another
  function Response:error(reason)
    self:writeHead(500,
      {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #reason
      })
    self:write(reason)
  end

  function Response:json(tbl)
    local res = json.encode(tbl)
    self:writeHead(200,
      {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #res
      })
    self:write(res)
  end
   
  local root = 'www'
    http_server = http.createServer(
      function(req, res)
        req.uri = url.parse(req.url)
          local path = root .. req.uri.pathname
          local paths = req.uri.pathname:split('/')
          local chunks = {}
          local length = 0

          req:on('data',
            function (chunk, len)
              length = length + 1
              chunks[length] = chunk
            end)

          req:on('end',
            function ()
              p('path',path)
              if paths[1] == 'api' then
                local data = json.decode(table.concat(chunks, ''))
		p(data, table.concat(chunks, ''))
		if not data or not data.pass or data.pass ~= webpass then return res:error('Forbidden') end
		local ret = { status = 'KO' }
                -- API SECTION

                if paths[2] then
                  if paths[2] == 'modules' then
                    if not paths[3] then
                      ret.data = {}
                      for name, cmd in pairs(commands) do
                        table.insert(ret.data,
                          { name = name,
                            display_name = cmd.display_name or name,
                            enabled = cmd.enabled })
                      end
                      ret.status = 'OK'
                    elseif paths[3] and commands[paths[3]] then
                      local cmd = commands[paths[3]]
                      if type(data.enabled) == 'boolean' then
                        cmd.enabled = data.enabled
                        db('UPDATE modules SET state = "'..tostring(cmd.enabled)..'" WHERE name = "'.. paths[3] .. '"')
                        print(paths[3]..' -> '..(cmd.enabled and 'en' or 'dis')..'abled')
                      elseif type(data.options) == 'table' and cmd.options then
                        for o, v in pairs(data.options) do
                          if cmd.options[o] then
                            db('UPDATE modules_config SET value = "'..(tostring(v):gsub('"','""'))..'" WHERE name = "'..(o)..'" AND module = "'..(cmd.name)..'"')
                          end
                        end
                        if cmd.on_option_update then
                          cmd.on_option_update(getModuleOptions(cmd.name))
                        end
                      else
                        ret.data = { name = cmd.name,
				     usage = cmd.usage,
				     description = cmd.description,
				     author = cmd.author,
				     display_name = cmd.display_name or cmd.name,
				     prefix = config.prefix,
                                     options = cmd.options,
                                     options_values = getModuleOptions(cmd.name) }
                      end
                      ret.status = 'OK'
                    end
                  end
                end
		      
		-- API SECTION END
                res:json(ret)
              else
                fs.stat(path,
                  function (err, stat)
                    if err then
                      if err.code == "ENOENT" then
                        return res:notFound(err.message .. "\n")
                      end
                        return res:error((err.message or tostring(err)) .. "\n")
                      end
                      if stat.type ~= 'file'    then
                        return res:notFound("Requested url is not a file\n")
                      end

                      res:writeHead(200,
                        {
                          ["Content-Type"] = getType(path),
                          ["Content-Length"] = stat.size
                        })
                      fs.createReadStream(path):pipe(res)
                    end)
                  end
              end)
      end)
end
