local fs = require('fs')

return function(path, filter)
  local dirs = {}
  filter = filter or (function() return true end)
  
  local stat = fs.statSync(path)
  if not stat or stat.type ~= 'directory' then return dirs end
  for i, name in ipairs(fs.readdirSync(path)) do
    local stat = fs.statSync(path.."/"..name)
    if stat.type == 'directory' then
      if filter(name) then
        dirs[#dirs + 1] = path.."/"..name
      end
    end
  end
  
  return dirs
end