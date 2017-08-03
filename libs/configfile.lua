local ts = require('./libs/tablesave')

return function(location, default)
  local cfg = {
    file = location,
    save = function(self)
      ts.save(self.data, self.file)
    end,
    load = function(self)
      self.data = ts.load(self.file)
    end
  }
  
  cfg:load()
  if type(cfg.data) == 'nil' then
    cfg.data = default or {}
    cfg:save()
  end

  return cfg
end