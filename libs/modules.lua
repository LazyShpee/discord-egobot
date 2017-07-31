local log = require('./libs/log')

-- load
-- unload

--loadfile ([filename [, mode [, env]]])

function loadModuleFile(self, filename)
  local func, syntax = loadfile(filename, 't')
  if not func and syntax then
    return nil, 'Error loading file "'..filename..'": '..syntax
  end
  
  local status, mod = pcall(func)
  if not status then
    return nil, 'Error running file "'..filename..'": '..mod
  end
  
  local needed = {'name'}
  for _, n in ipairs(needed) do
    if not mod[n] then
      return nil, 'Error missing "'..n..'" field in file '..filename
    end
  end
  
  mod.file = filename
  if self._mods[mod.name] then
    return nil, 'Module name "'..mod.name..'" already taken by file '..self._mods[mod.name].file
  end
  
  self._mods[mod.name] = mod
  
  if type(mod.enableDefault) == 'nil' then
    mod.enableDefault = true
  end
  
  local enabled = self._config.modules.data[mod.name]
  if type(enabled) == 'nil' then
    self._config.modules.data[mod.name] = mod.enableDefault
    enabled = mod.enableDefault
  end
  
  if enabled then
    local e, m = self:enable(mod.name)
    if not e then return e, m end
  end

  return mod
end

function unloadModule(self, name)
  if not self._mods[name] then
    return nil, 'Could not unload "'..name..'": module not loaded'
  end

  local e, m = self:disable(name)
  if not e then return e, m end
  
  self._mod[name] = nil
  return name
end

function enableModule(self, name)
  local mod = self._mods[name]
  if not mod then
    return nil, 'Module "'..name..'" is not loaded'
  end
  
  if mod.enable and self._config.modules.data[name] then
    local status, r, s = pcall(mod.enable, mod)
    if not status then
      return nil, 'Error trying enabling module "'..mod.name..'": '..r
    end
    if type(r) == 'boolean' and not r then
      return nil, 'Could not enable module "'..mod.name..'": '..s
    end
  end
  return true
end

function disableModule(self, name)
  local mod = self._mods[name]
  if not mod then
    return nil, 'Module "'..name..'" is not loaded'
  end
  
  if mod.disable and not self._config.modules.data[name] then
    local status, err, err2 = pcall(mod.disable, mod)
    if not status then
      return nil, 'Could not disable "'..name..'": '..err
    elseif type(err) == 'boolean' and not err then
      return nil, 'Could not disable "'..name..'": '..err2
    end
  end
  return true
end

function execModules(self, command, args)
  local name, argument = command:match('^(%S+)%s*(%S*.-)%s*$')
  if name and argument then
    if self._config.modules.data[name] and self._mods[name] and type(self._mods[name].call) == 'function' then
      local status, err = pcall(self._mods[name].call, self._mods[name], argument, args)
      p('command', name, argument)
      if not status then
        log('Error while calling module "'..name..'": '..err)
      end
    end
  end
end

return function(client, config)
  return setmetatable({
    _mods = {},
    _client = client,
    _config = config,
    load = loadModuleFile,
    unload = unloadModule,
    enable = enableModule,
    disable = disableModule,
    exec = execModules
  }, {__len = function(self) local i = 0 for _ in pairs(self._mods) do i = i + 1 end return i end})
end