local ts = require('./libs/tablesave')

return function(location, default)
  local cfg = {
    file = location,
    save = function(self)
      ts.save(self.data, self.file)
    end,
    load = function(self)
      local data, err = ts.load(self.file)
      if err then
        print('Fatal error loading '..self.file..': '..err)
        os.exit()
      end
      self.data = data
    end
  }
  
  cfg:load()
  if type(cfg.data) == 'nil' then
    cfg.data = default or {}
    cfg:save()
  end

  return cfg
end