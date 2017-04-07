local spe = {
  ['-'] = 'heavy_minus_sign',
  ['+'] = 'heavy_plus_sign',
  ['*'] = 'heavy_disivion_sign',
  ['/'] = 'heavy_multiplication_sign',
  ['$'] = 'heavy_dollar_sign',
  ['>'] = 'arrow_right',
  ['<'] = 'arrow_left',
  ['!'] = 'exclamation',
  ['?'] = 'question',
  ['0'] = 'zero',
  ['1'] = 'one',
  ['2'] = 'two',
  ['3'] = 'three',
  ['4'] = 'four',
  ['5'] = 'five',
  ['6'] = 'six',
  ['7'] = 'seven',
  ['8'] = 'eight',
  ['9'] = 'nine'
}

local function rep(c)
  if spe[c] then
    return ':'..spe[c]..': '
  elseif c:match('[a-zA-Z]') then
    return ':regional_indicator_'..c:lower()..': '
  else
    return c
  end
end

local _EM = {
  name = 'em',
  call = function(m, c, a)
    local rep = a:gsub('.', rep)
    m:delete()
    m:reply(rep)
  end,
  author = 'LazyShpee',
  usage = '<text>',
  description = 'Transforms text into regional indicator and various symbol emote',
  display_name = 'Emote Text'
}

return _EM
