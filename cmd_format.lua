local _, util = ...
local ascii_emotes = setmetatable({
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
})

local _FORMAT = {
   name = 'f',
   call = function (m, c, a)
      if not a or #a == 0 then return end
      local res = a:gsub('{([^}]+)}',
			 function(e)
			    local s, r = util.eval_math(e)
			    return s and e..'='..tostring(r) or e..'='..'ERR'
			 end
      ):gsub('<([^>]+)>',
	     function (e)
		return ascii_emotes[e]
	     end
	    )
      m.content = res
   end,
   author = 'LazyShpee'
}

return _FORMAT
