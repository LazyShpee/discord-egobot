local log = require('logger')

-- Inspired by Siapran
local _LATEX = {
   name = 'tex',
   call = function(m, c, a)
      if #a == 0 then return end

      local text = a:gsub('```%w*\n?', ''):gsub('^`', ''):gsub('`$', '')
      
      local tex = io.open('tmp_latex.tex', 'w')
      tex:write([[\documentclass[varwidth,border=0.50001bp,convert={density=300 -flatten,outext=.png}]{standalone}
\usepackage[utf8]{inputenc}
\begin{document}
]])
      tex:write(text..'\n')
      tex:write([[\end{document}]])
      tex:close()

      os.execute('pdflatex -shell-escape tmp_latex.tex')
      log('Texed `'.. text ..'`')
      m:reply({file = './tmp_latex.png'})
      m:delete()
      os.execute('rm -f tmp_latex.pdf tmp_latex.log tmp_latex.aux tmp_latex.tex tmp_latex.png')
   end,
   usage = '```[latex code here]```',
   description = [[Compile latex code into an image and posts it]],
   display_name = 'LaTeX',
   options = {
      alpha = { type = 'toggle', label = 'Alpha Background', default = false }
   }
}

return _LATEX
