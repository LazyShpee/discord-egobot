local _M = {}
local M = setmetatable({}, _M)

M.Error         = {'E', '31'} -- red
M.Info          = {'I', '32'} -- green
M.Warning       = {'W', '33'} -- yellow
M.Default       = {' ', ''}
M.Normal        = {' ', ''}

_M.__index        = function (self, k)
  return self.Default
end

_M.__call = function (self, m, e, emmiter)
  if type(e) ~= 'table' or #e ~= 2 then e = self[e] end
  local c = '\27['..e[2]..'m' or ''
  print(c..'['..e[1]:upper()..']'..os.date('[%D %R] ')..tostring(m)..'\27[0m')
end

M('Logger active', M.Info, 'self')

return M