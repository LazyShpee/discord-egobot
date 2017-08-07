local emoji = require('./libs/emojis')

local function printLine(...)
  local ret = {}
  for _, v in ipairs({...}) do
    table.insert(ret, tostring(v))
  end
  return table.concat(ret, '\t')
end

local sandbox = {}

local function reset()
  sandbox = {}
  setmetatable(sandbox, {__index = _G})
end

reset()

return {
  name = 'eval',
  call = function(self, a, args)
    local msg, tf = args.message
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
    sandbox.print = function(...) local p = printLine(...) table.insert(output, p) end
    
    local fn, syntax = load(tf, 'eval', 't', sandbox)
    if not fn then return m:reply('```\n'..syntax..'```') end
    local success, runtime = pcall(fn)
    if not success then return m:reply('```\n'..runtime..'```') end
    
    if #output == 0 then
      msg:addReaction(emoji.heavy_check_mark)
    else
      local o = table.concat(output, '\n')
      if #o > 1985 then
        o = o:sub(1, 1985)..'\n[...]'
      end
      msg:reply('```\n'..o..'```')
    end
  end
}