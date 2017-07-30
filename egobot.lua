local discordia = require('discordia')
local client = discordia.Client()

local configFile = require('./libs/config')
local getfiles = require('./libs/getfiles')

local data = {
  modules = configFile('./data/modules.lua'),
  options = configFile('./config.lua')
}

local modules = require('./libs/modules')(client, data)
local log = require('./libs/log')
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
    text = 'Displays this help message'
  }
})

local argv = parser:parse(args, 2)
for i in pairs(args) do args[i] = nil end
if not argv.token or argv.help then
  print(parser:help())
  os.exit(1)
end

log('Getting ready...')

for _, filepath in ipairs(getfiles('./mods')) do
  local status, err = modules:load(filepath)
  if not status and err then
    log(err)
  end
end
data.modules:save()

log('Loaded '..#modules..' module(s).')

client:on('ready', function()
  log('Egobot-rw ready for action o7')
  log('Logged in as '..client.user.username..'#'..client.user.discriminator..' ('..client.user.id..')')
end)

client:on('messageCreate', function(message)
  if client.user.id ~= message.author.id then return end
  if message.content:sub(1, #data.options.data.prefix) == data.options.data.prefix then
    modules:exec(message.content:sub(#data.options.data.prefix + 1), {message = message})
  end
end)

client:on('warning', function() end)

client:run(argv.token)