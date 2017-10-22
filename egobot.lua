math.randomseed(os.time())

local discordia = require('discordia')
local client = discordia.Client{
  cacheAllMembers = true,
  logLevel = discordia.enums.logLevel.error
}

local db = require('./libs/db')
local ts = require('./libs/tablesave')
local getdirs = require('./libs/getdirs')
const = require('libs/const')
  const.client = client
  const.startTime = os.date('!%Y-%m-%dT%H:%M:%S')
  const.hostname = io.popen('hostname'):read()
  const.version = io.popen('git show-ref --head --abbrev --hash'):read()
  const.getfiles = getfiles
  const.db = db
  const.require = require
  const.pp = require('pretty-print')
  const.enums = discordia.enums

local log = require('./libs/log')
  const.log = log

local data = db("./data/db")
  const.data = data

if not data:exists('config') then -- Default config
  data.config = {
    prefix = '.'
  }
end

--[[
  Command line argument parsing and use
]]

local parser = require('./libs/argparse').new({
  token = {
    long = 'token',
    short = 't',
    type = 'token',
    text = 'One of your discord account\'s tokens'
  },
  help = {
    long = 'help',
    short = 'h',
    text = 'Displays this help message and exit, nothing is saved'
  },
  cfgToken = {
    short = 'T',
    text = 'Sets the token to use if none is provided (default: none)',
    type = 'token'
  },
  cfgPrefix = {
    short = 'P',
    text = 'Sets the prefix to use if none is provided (default: .)',
    type = 'any'
  },
  configOnly = {
    short = 'E',
    text = 'Exit after saving (new) config'
  }
})

local argv = parser:parse(args, 2)
for i in pairs(args) do args[i] = nil end

if argv.help then
  print(parser:help())
  os.exit(1)
end

if argv.cfgToken then
  data.config.token = argv.cfgToken
  log('Set new token', log.Info)
end

if argv.cfgPrefix then
  data.config.prefix = argv.cfgPrefix
  log('Set new prefix to '..argv.cfgPrefix, log.Info)
end

data:save('config')

if argv.configOnly then
  os.exit(1)
end

if not (argv.token or data.config.token) then
  print('You must provide a token with the option -t or set it for later use with -T.\nSee --help.')
  os.exit(2)
end

--[[
  Webui stuff
]]

--local ui = require('./libs/webui')

--[[
  Module loading
]]

local modules = require('./libs/modules')(client, {}, data) -- unused config for now, might get removed
  const.modules = modules

log('Getting ready...', log.Info)

modules:load(getdirs('./mods'))

log('Loaded '..#modules..' module(s).',log.Info)

--[[
  Client events
]]

client:on('ready', function()
  if client.user.bot then
    log('This is a selfbot, you should be using a discord user account token.', log.Error)
    client:stop()
    return
  end
  log('Egobot-rw ready for action o7', log.Info)
  log('Logged in as '..client.user.username..'#'..client.user.discriminator..' ('..client.user.id..')', log.Info)
end)

client:on('messageCreate', function(message)
  if client.user.id ~= message.author.id then return end
  if message.content:sub(1, #data.config.prefix) == data.config.prefix then
    modules:exec(message.content:sub(#data.config.prefix + 1), {message = message})
  end
end)

client:run(argv.token or data.config.token)