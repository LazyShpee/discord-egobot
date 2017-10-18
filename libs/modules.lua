
--[[

user/

data/

mods/
  samplemodule/
    init.lua
    www/

]]--

function loadModule(self, name)

end

function execModule(self, command, args)

end






return function(client, config)
  return setmetatable({
    _mods = {},
    _client = client,
    _config = config,
    load = loadModule,
    exec = execModule
  }, {__len = function(self) local i = 0 for _ in pairs(self._mods) do i = i + 1 end return i end})
end