local M = {}

--[[

config = {
  option_name = {
    long = '',
    short = '',
    type = '',
    text = ''
  }
}

]]

local function b(bool)
  return bool and 1 or 0
end

local types = {
  any = { '.+' },
  number = { '[+-]*[0-9]+', tonumber },
  word = { '%w+'},
  token = { '[%w._-]+' }
}

local function esc(str)
  return str:gsub('[%-.*?]', '%%%0')
end

local function checktype(val, typename)
  if types[typename] then
    if val:match('^'..types[typename][1]..'$') then
      return types[typename][2] and types[typename][2](val) or val
    end
  end
end

local function parse(self, argv, start)
  local a = {}

  for i=start or 1,#argv do
    local pa = #argv - i -- Possible remaining arguments
    local v = argv[i]
    
    for n, o in pairs(self.config) do
      if (o.short and v:sub(2, #v) == o.short) or (o.long and v:sub(3, #v) == o.long) then
        if o.type then
          if pa >= 1 then
            i = i + 1
            a[n] = checktype(argv[i], o.type)
            break
          end
        else
          a[n] = true
          break
        end
      elseif (o.type and o.long and v:match('^%-%-'..esc(o.long)..'=.+$')) then
        a[n] = checktype(v:match('^%-%-'..esc(o.long)..'=(.+)$'), o.type)
        break
      end
    end
  end
  return a
end

local function help(self)
  local h = "Available arguments:\n"
  for i, o in pairs(self.config) do
    h = h..(' '):rep(3)
    if o.short then h = h..' -'..o.short     end
    if o.long  then h = h..' --'..o.long     end
    if o.type  then h = h..' <'..o.type..'>' end
    if o.text  then h = h..' : '..o.text     end
    h = h..'\n'
  end
  return h
end

function M.new(config)
  return {config = config or {}, parse = parse, help = help}
end

return M