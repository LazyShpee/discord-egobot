local md5 = require('./libs/md5')

local fmt = {
  ae = function(s)
    local r = ''
    for i=1,#s do
      local v = s:sub(i, i):byte(1)
      if v == 32 then -- Special case for space
        r = r .. string.char(227, 128, 128)
      elseif v >= 33 and v <= 95 then -- ! to _
        r = r .. string.char(239, 188, v - 33 + 129)
      elseif v >= 96 and v <= 127 then -- ` to ~
        r = r .. string.char(239, 189, v - 96 + 128)
      else
        r = r .. string.char(v)
      end
    end
    return r
  end,
  
  sb = function(s)
    return s:gsub('[a-zA-Z]', function(r)
      if math.random(2) == 1 then
        return r:upper()
      else
        return r:lower()
      end
    end)
  end
}

return function(str)
  return str:gsub('{(%S+)%s+(%S.*)}', function(op, param)
    if fmt[op] then
      return fmt[op](param)
    end
  end)
end