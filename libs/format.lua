local md5 = require('./libs/md5')

local fmt = {
  ae = function(s) -- Convert any ascii to fullwidth
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
  
  sb = function(s) -- Retarded spongebob
    return s:gsub('[a-zA-Z]', function(r)
      if math.random(2) == 1 then
        return r:upper()
      else
        return r:lower()
      end
    end)
  end,
  
  sp = function(s) -- Adds spaces after every characters
    return s:gsub('(.)', function(c)
      if c:byte(1) < 127 then
        return c..' '
      end
    end):gsub(' +$', '')
  end,
  
  ro = function(s) -- Randomly shuffles words
    local ws = {}
    for w in s:gmatch('%S+') do
      ws[#ws + 1] = w
    end
    for i=1,#ws do
      local r = math.random(#ws)
      ws[i], ws[r] = ws[r], ws[i]
    end
    return table.concat(ws, ' ')
  end,
  
  cw = function(s)
    return (' '..s):gsub('[^_0-9a-zA-Z][a-zA-Z]', function(l) return l:upper() end):sub(2)
  end,
  
  lo = string.lower,
  up = string.upper,
  
  md5 = md5.sumhexa,
  
  txt = function(path)
    local fd = io.open('./user/'..path)
    if fd then
      local all = fd:read('*all')
      fd:close()
      return all
    end
    return ''
  end,
  
  rl = function(path)
    local fd = io.open('./user/'..path)
    if fd then
      local cont, line = {}, fd:read('*line')
      while line do
        cont[#cont + 1] = line
        line = fd:read('*line')
      end
      cont[#cont + 1] = line
      fd:close()
      return cont[math.random(#cont)]
    end
    
    return ''
  end
}

-- Eventual TODO: Nested formats

return function(str, path)
  path = path or './user/'
  return str:gsub('{(%S+)%s+(%S.-)}', function(ops, param)
    for op in ops:gmatch('[^+]+') do
      if fmt[op] then
        param = fmt[op](param, path)
      else
        return
      end
    end
    return param
  end)
end