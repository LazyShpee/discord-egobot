local _, util = ...
local ascii_emotes = setmetatable(
  {
    zoidberg = '(V) (°,,,,°) (V)',
    check = '✓',
    cmd = '⌘',
    communism = '☭',
    carecup = 'c\\\\_/',
    lenny = '( ͡° ͜ʖ ͡°)',
    shrug = '¯\\_(ツ)_/¯',
    angry = 'ಠ_ಠ',
    flip = '(╯°□°）╯︵ ┻━┻',
    unflip = '┬──┬◡ﾉ(° -°ﾉ)',
    yeah = [[( •_•)                          
( •_•)>⌐■-■                                    
(⌐■_■) YEAAAAAH !]],
    bear = 'ʕ•ᴥ•ʔ',
    creep = 'ಠᴗಠ',
    confused = '(⊙_☉)',
    kiss = '(づ￣ ³￣)づ',
    yudodis = 'ლ(ಠ_ಠლ)',
    money = '[̲̅$̲̅(̲̅ ͡° ͜ʖ ͡°̲̅)̲̅$̲̅]',
    judge = 'ఠ_ఠ',
  },
  {
      __index = function(t, k) return k end
  }
)

local function to_full(s)
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
end

local e = {}
for i in pairs(ascii_emotes) do table.insert(e, i) end
e = table.concat(e, ', ')

local _FORMAT = {
  name = 'f',
  call = function (m, c, a)
    if not a or #a == 0 then return end
    local res = a:gsub('{([^}]+)}',
      function(e)
        local s, r = util.eval_math(e)
        return s and e..'='..tostring(r) or e..'='..'ERR'
      end)
    :gsub('<([^>]+)>',
      function (e)
        return ascii_emotes[e]
      end)
    m.content = res
  end,
  author = 'LazyShpee',
  usage = '<message to format>',
  display_name = 'Formatter',
  description = [[Adds inline ascii emotes and math to message
Use `{expr}` for math and `<emote name>` for emotes
Available emotes are:
]]..e
}

local _FULLWIDTH = {
  name = 'fullwidth',
  call = function(m, c, a)
    m:reply(to_full(a))
    m:delete()
  end,
  usage = '<text>',
  description = [[Converts ascii characters in text to fullwidth (aethetics) text]],
  author = 'LazyShpee'
}

return _FORMAT, _FULLWIDTH
