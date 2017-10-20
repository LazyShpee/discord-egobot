local ts = require("./libs/tablesave")
local fs = require("fs")

local function save(self, name)  
  if type(self._tables[name]) ~= 'table' then return end
  
  local path = self._dir..'/db_'..name..'.lua'
  ts.save(self._tables[name], path)
end

local function loadAll(self)
  local stat = fs.statSync(self._dir)
  if stat and stat.type ~= "directory" then error("Could not open directory "..self._dir) end
  if not stat then fs.mkdirSync(self._dir) end
  for i, filename in ipairs(fs.readdirSync(self._dir)) do
    if filename:find('^db_[a-zA-Z0-9]+%.lua$') then
      local name = filename:match('^db_([a-zA-Z0-9]+)%.lua$')
      self._tables[name] = ts.load(self._dir..'/'..filename)
    end
  end
end

local function saveAll(self)
  for k, v in pairs(self._tables) do
    self:save(k)
  end
end

local function exists(self, name)
  return type(self._tables[name]) == 'table'
end

return function(dir)
  local index = {
    _dir = dir,
    _tables = {},
    save = save,
    saveAll = saveAll,
    loadAll = loadAll,
    exists = exists
  }
  
  local db = setmetatable({}, {
    __index = function(s, k)
      if type(index[k]) ~= 'nil' then return index[k] end
      if type(index._tables[k]) ~= 'nil' then return index._tables[k] end
    end,
    __newindex = function(s, k, v)
      if type(index[k]) ~= 'nil' then error("Reserved keyword") end
      if not k:find("^[a-zA-Z0-9]+$") then error("Only alphanumerical name are supported") end
      if type(v) ~= 'table' and type(v) ~= 'nil' then
        error("Tables can only be tables")
      end
      index._tables[k] = v
      if type(v) == 'nil' then
        fs.unlinkSync(index._dir..'/db_'..k..'.lua')
      end
    end
  })
  
  db:loadAll()
  
  return db
end