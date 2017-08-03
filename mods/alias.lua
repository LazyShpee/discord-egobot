local const = require('libs/const')
local configFile = require('./libs/configfile')

local aliases = configFile('./data/aliases.lua')

local function aliasHook(message)
  if message.client.user.id ~= message.author.id then return end
  local prefix = const.data.options.data.prefix
  if message.content:sub(1, #prefix) == prefix then
    local name, argument = message.content:sub(#prefix + 1):match('^(%S+)%s*(%S*.-)%s*$')
    local alias = aliases.data[name]
    if alias and 
      not (const.modules._mods[name] and 
      const.modules._mods[name].call) then -- alias exists and modules doesnt or doesn't have a call method'
        local value = alias.value
        if alias.params then
          if alias.params == 'after' then
            value = value..' '..argument
          elseif alias.params == 'inline' then
            value = value:format(argument)
          elseif alias.params == 'before' then
            local cmd, arg = value:match('^(%S+)(.*)$')
            value = cmd..' '..argument..arg
          end
        end
        p('alias', name, argument)
        const.modules:exec(value, {message = message})
    end
  end
end

return {
  name = 'alias',
  
  enable = function(self, client)
    client:on('messageCreate', aliasHook)
    aliases:load()
  end,
  disable = function(self, client)
    client:removeListener('messageCreate', aliasHook)
    aliases:save()
  end
}