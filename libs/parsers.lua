local groupers = {
  ['"'] = '"',
  ["'"] = "'",
  ['['] = ']',
  ['('] = ')',
  ['{'] = '}'
}

local escaper = '\\'
local separator = ' '

local function bash_args(str)
  local args = {}
  
  local esc, group, arg = false, nil, ''
  for i=1,#str do
    local c = str:sub(i, i)
    if not esc and c == escaper then
      esc = true
    elseif esc then
      arg = arg..c
      esc = false
    elseif not group and c == separator then
      if #arg > 0 then
        args[#args + 1] = arg
      end
      arg = ''
    elseif not group and groupers[c] then
      group = c
    elseif group and c == groupers[group] then
      group = nil
    else
      arg = arg..c
    end
  end
  if #arg > 0 then
    args[#args + 1] = arg
  end

  return args
end

return {bash = bash_args}