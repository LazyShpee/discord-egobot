local _, util = ...
local log = require('utils.logger')

local _MATH = {
  name = 'math',
  call = function (m, c, a)
    local status, res = util.eval_math(a)
    log('Evaluated math `'..a..'`', nil, 'math')
    m.content = util.code(a..'=\n'..tostring(res)) -- replace with result
  end,
  usage = '<mathematical expression>',
  author = 'LazyShpee',
  description = 'Evaluate a Lua mathematical expression (no need to use prefix math. )'
}

return _MATH
