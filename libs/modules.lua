local log = require('./libs/log')
local fs = require('fs')

--[[
Structure
  user/

  data/

  mods/
    samplemodule/
      init.lua
      www/

Sample Module
{
  name = ""
}    

]]--

local function loadModule(self, name, save)
  if not self._data:exists("modules") then
    self._data.modules = {}
  end

  if type(name) == "string" then -- Load single module
    local stat = fs.statSync(name..'/init.lua')
    if not stat or stat.type == 'directory' then return nil, 'init.lua file not found' end
    
    local func, syntax = loadfile(name..'/init.lua', 't', setmetatable({db = self._data}, {__index = _G}))
    if not func and syntax then
      return nil, syntax
    end
    
    local status, mod = pcall(func)
    if not status then
      return nil, mod
    end
    
    local needed = {'name'}
    for _, n in ipairs(needed) do
      if not mod[n] then
        return nil, 'Missing field "'..n..'"'
      end
    end
    
    mod.dir = name
    if self._mods[mod.name] then
      return nil, 'Mod name "'..mod.name..'" already used'
    end

    self._mods[mod.name] = mod
    
    local enabled = self._data.modules[mod.name]
    if type(enabled) == 'nil' then
      self._data.modules[mod.name] = true
    end
    
    if self._data.modules[mod.name] == true then
      self:toggle(mod.name, true, true)
    end
    
    return true
  elseif type(name) == "table" then -- Iterate to call as single module and then save
    for k, v in ipairs(name) do
      local s, e = self:load(v)
      if not s then
        log('Module "'..v..'" not loaded:'..e, log.Warning)
      end
    end
    self._data:save("modules")
  end
end

local function toggleModule(self, name, state, force) -- true/false, enable/disable
  if not self._mods[name] or type(self._data.modules[name]) ~= 'boolean' then
    return nil, 'Module '..name..' does not exist'
  end
  if self._data.modules[name] ~= state or force then
    local mod = self._mods[name]
    if state == true then
      if type(mod.enable) == 'function' then
        pcall(mod.enable, mod, self._client)
      end
      self._data.modules[name] = true
    elseif state == false then
      if type(mod.disable) == 'function' then
        pcall(mod.disable, mod, self._client)
      end
      self._data.modules[name] = false
    end
  end
end

local function execModule(self, command, args)
  local name, argument = command:match('^(%S+)%s*(%S*.-)%s*$')
  if name and argument then
    if self._data.modules[name] and self._mods[name] and type(self._mods[name].call) == 'function' then
      local status, err = pcall(self._mods[name].call, self._mods[name], argument, args)
      p('command', name, argument)
      if not status then
        log('Error while calling module "'..name..'": '..err)
      end
    end
  end

end






return function(client, config, data)
  return setmetatable({
    _mods = {},
    _client = client,
    _config = config,
    _data = data,
    load = loadModule,
    exec = execModule,
    toggle = toggleModule
  }, {__len = function(self) local i = 0 for _ in pairs(self._mods) do i = i + 1 end return i end})
end