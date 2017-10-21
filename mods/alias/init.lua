local const = require('libs/const')
local emoji = require('./libs/emojis')

if not db:exists('aliases') then
  db.aliases = {}
end
local aliases = db.aliases

local bash = require('./libs/parsers').bash

local fmt = {
  s = function (s) return (s) end,
  i = function (i) return (i:gsub('[^%d]+', '')) end
}

local fmts = {}
for i in pairs(fmt) do
  fmts[#fmts+1]=i
end
fmts = table.concat(fmts)

local function aliasHook(message)
  if message.client.user.id ~= message.author.id then return end
  local prefix = db.config.prefix
  if message.content:sub(1, #prefix) == prefix then
    local name, argument = message.content:sub(#prefix + 1):match('^(%S+)%s*(%S*.-)%s*$')
    local alias = aliases[name]
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
            value = value:gsub('%%%%', '\1'):gsub('%%([0-9]-)(['..fmts..'])', function(_n, f)
              local num = tonumber(_n)
              local s
              if fmt[f] then
                s = fmt[f](args[num or n] or '')
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
      aliases[alias] = aliases[alias] or {}
      aliases[alias].value = arg
      aliases[alias].params = aliases[alias].params or 'inline'
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'delete' and #alias > 0 and aliases[alias] then
      aliases[alias] = nil
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'show' and #alias > 0 and aliases[alias] then
      local desc = aliases[alias].value
      if arg ~= 'raw' then
        desc = '```\n'..desc..'```'
      end
      args.message:reply({embed = {
        author = {name = alias},
        description = desc,
        color = 16384030,
        fields = {{
          name = 'Arguments type',
          value = aliases[alias].params or 'None'
        }}
      }})
    elseif action == 'save' then
      db:save('aliases')
      args.message:addReaction(emoji.heavy_check_mark)
    --elseif action == 'reload' then
    --  aliases:load()
    --  args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'params' and #alias > 0 and aliases[alias] then
      if #arg == 0 then
        aliases[alias].params = nil
      else
        aliases[alias].params = arg:lower()
      end
      args.message:addReaction(emoji.heavy_check_mark)
    elseif action == 'list' then
      local _a = {}
      for a in pairs(aliases) do _a[#_a + 1] = a end
      args.message:reply({embed = {title = 'List of aliases', description = '`'..table.concat(_a, '`, `')..'`'}})
    else
      args.message:addReaction(emoji.question)
    end
  end,
  
  enable = function(self)
    client:on('messageCreate', aliasHook)
  end,
  disable = function(self)
    client:removeListener('messageCreate', aliasHook)
  end
}