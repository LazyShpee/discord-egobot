local emoji = require('./libs/emojis')

local function printLine(...)
  local ret = {}
  for _, v in ipairs({...}) do
    table.insert(ret, tostring(v))
  end
  return table.concat(ret, '\t')
end

local sandbox = {}

local function color(a, b, c)
  -- from discordia Color.lua
  local value
  if a and b and c then
    value = bit.lshift(a, 16) + bit.lshift(b, 8) + c
  elseif a then
    if type(a) == 'string' then
      value = tonumber(a:gsub('#', ''), 16)
    else
      value = tonumber(a)
    end
  end
  
  return value or 0
end

local function reset()
  sandbox = {color = color}
  setmetatable(sandbox, {__index = _G})
end

reset()

return {
  name = 'eval',
  call = function(self, a, args)
    local m, tf = args.message
    if     a:match("^```[^\n]-\n(.*)```$") then       tf = a:match("^```[^\n]-\n(.*)```$")
    elseif a:match("^`(.*)`$") then                   tf = a:match("^`(.*)`$")
    else                                              tf = a
    end
    if #tf == 0 then return end
    
    local output = {}
    sandbox.message = args.message
    sandbox.client = args.message.client
    sandbox.guild = args.message.guild
    sandbox.channel = args.message.channel
    sandbox.emoji = emoji
    sandbox.print = function(...) local p = printLine(...) table.insert(output, p) end
    
    local fn, syntax = load(tf, 'eval', 't', sandbox)
    if not fn then return m:reply('```\n'..syntax..'```') end
    local success, runtime = pcall(fn)
    if not success then return m:reply('```\n'..runtime..'```') end
    
    if #output == 0 then
      m:addReaction(emoji.heavy_check_mark)
    else
      local o = table.concat(output, '\n')
      if #o > 1985 then
        o = o:sub(1, 1985)..'\n[...]'
      end
      m:reply('```\n'..o..'```')
    end
  end
}