
local mime = require('mime')
local app = require('weblit-app')
local fs = require('fs')

local db = require('libs/const').data
local log = require('./libs/log')

local tabs = {}
local endpoints = {}

local ui = {
  start = function()
    app.start()
  end,
  addTab = function(self, name, path, label)
    if tabs[name] then
      log('A tab named '..name..' already exists.', log.Warning)
      return false
    end
    tabs[name] = {path = path, }
  end,
  removeTab = function(self, name)
    tabs[name] = nil
  end,
  addEndpoint = function(self, name, handler)
  
  end,
  removeEndpoint = function(self, name)
    endpoints[name] = nil
  end
}



--[[
  Web UI Core
]]

function string:random(len)
  local r = ''
  for i=1,(len or 8) do
    local rn = math.random(1, #self)
    r = r..self:sub(rn, rn)
  end
  return r
end

function string:charset()
  local pat = '^['..self..']$'
  local cs = ''
  for i=0,127 do
    local char = string.char(i)
    if char:match(pat) then cs = cs .. char end
  end
  return cs
end

local charset = ('%a%d'):charset()

if not db:exists('cookies') then
  db.cookies = {}
end

app.bind({
  host = '0.0.0.0',
  port = 8080
})

-- Route handling

local root = './data/www'

app.route({ -- Auth and frontend
  method = 'GET'
}, function (req, res, go)
  p(req)
end)

.route({ -- API Calls
  method = 'POST'
}, function (req, res, go)

end)

.start()

return ui