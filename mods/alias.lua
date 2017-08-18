local const = require('libs/const')
local configFile = require('./libs/configfile')
local emoji = require('./libs/emojis')
local aliases = configFile('./data/aliases.lua')
local bash = require('./libs/parsers').bash

local fmt = {
  s = function (s) return (s) end
}

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
            local args = bash(argument)
            args[0] = argument
            local n = 1
            value = value:gsub('%%%%', '\1'):gsub('%%([0-9]-)([s])', function(_n, f)
              local num = tonumber(_n)
              local s
              if args[num or n] and fmt[f] then
                s = fmt[f](args[num or n])
              end
              if not num then
                n = n + 1
              end
              return s
            end):gsub('\1', '%%')
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
  
  call = function(self, argument, args)
    local action, alias, arg = argument:match('^(%S*)%s*(%S*)%s*(.*)$')
    if action == 'set' and #alias > 0 and #arg > 0 then
      aliases.data[alias] = aliases.data[alias] or {}
      aliases.data[alias].value = arg
      aliases.data[alias].params = aliases.data[alias].params or 'inline'
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'delete' and #alias > 0 and aliases.data[alias] then
      aliases.data[alias] = nil
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'show' and #alias > 0 and aliases.data[alias] then
      local desc = aliases.data[alias].value
      if arg ~= 'raw' then
        desc = '```\n'..desc..'```'
      end
      args.message:reply({embed = {
        author = {name = alias},
        description = desc,
        color = 16384030,
        fields = {{
          name = 'Arguments',
          value = aliases.data[alias].params or 'None'
        }}
      }})
    elseif action == 'save' then
      aliases:save()
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'reload' then
      aliases:load()
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'params' and #alias > 0 and aliases.data[alias] then
      if #arg == 0 then
        aliases.data[alias].params = nil
      else
        aliases.data[alias].params = arg:lower()
      end
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'list' then
      local _a = {}
      for a in pairs(aliases.data) do _a[#_a + 1] = a end
      args.message:reply({embed = {title = 'List of aliases', description = '`'..table.concat(_a, '`, `')..'`'}})
    else
      args.message:addReaction(emoji.question)
    end
  end,
  
  enable = function(self, client)
    client:on('messageCreate', aliasHook)
    aliases:load()
  end,
  disable = function(self, client)
    client:removeListener('messageCreate', aliasHook)
    aliases:save()
  end
}