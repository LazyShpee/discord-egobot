local fs = require('fs')

return function(path, filter)
  local files = {}
  filter = filter or (function() return true end)
  
  local function goIn(path, file, depth)
    local stat = fs.statSync(path)
    if not stat then return files end
    if stat.type == 'file' then if filter(path, file, depth) then  files[#files + 1] = path end return files end
    for i, filename in ipairs(fs.readdirSync(path)) do
      goIn(path..'/'..filename, filename, depth + 1)
    end
  end
  
  goIn(path, path:gsub('^.*/', ''), -1)
  return files
end