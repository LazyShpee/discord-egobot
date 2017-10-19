return function(text, level, context)
  if not text then return end
  print('['..os.date('%d/%m/%y %X')..'] '..text)
end