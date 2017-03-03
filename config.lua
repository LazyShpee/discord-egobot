local colors = {
   red    = '31',
   yellow = '33',
   green  = '32'
}

local ascii_emotes = {
   zoidberg = '(V) (°,,,,°) (V)',
   check = '✓',
   cmd = '⌘',
   communism = '☭',
   carecup = 'c\\_/',
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
}

return {
   prefix = '::',
   error_levels = {
      w = colors.yellow,
      e = colors.red,
      i = colors.green,
      d = ''
   }
}, colors, ascii_emotes
