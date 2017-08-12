local function istr(ind)
  if type(ind) == 'string' then
    if ind:match('^[a-zA-Z_][a-zA-Z0-9_]*$') then
      return ind
    end
    return '["'..ind:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')..'"]'
  end
  return '['..ind..']'
end

local function tdisplay(t, o, i)
  i = i or 0
  o = o or {}
  local indent = o.indent or 2
  local r = ''
  
  r = '{\n'
  for _i, _v in pairs(t) do
    local ty = type(_v)
    r = r .. (' '):rep((i + 1) * indent) .. istr(_i) .. ' = '
    if ty == 'table' then
      r = r .. tdisplay(_v, o, i + 1)
    elseif ty == 'number' or ty == 'boolean' or ty == 'nil' then
      r = r .. tostring(_v)
    elseif ty == 'string' then
        r = r .. '"' .. _v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    end
    r = r .. ',\n'
  end
  r = r..(' '):rep(i * indent)..'}'
  return r
end

local function tsave(t, f)
  local ts = tdisplay(t)
  local fd = io.open(f, 'w')
  if not fd then return nil, 'Error opening "'..f..'"' end
  fd:write(ts..'\n')
  fd:close()
  return true
end

local function tload(f)
  local fd = io.open(f, 'r')
  if not fd then return nil, 'Error opening "'..f..'"' end
  local ts = fd:read('*all') or '{}'
  fd:close()
  
  local func, syntax = load('return '..ts, 'table.load', 't', {})
  if syntax then return nil, syntax end
  
  local status, t = pcall(func)
  if not status then return nil, t end
  return t
end

return {
  td = tdisplay,
  save = tsave,
  load = tload
}