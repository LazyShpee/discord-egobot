local format = require('./libs/format')
local const = require('libs/const')

return {
  name = 's',
  call = function(self, argument, args)
  
    local reply = {}
    local nd = false
    local files = {}

    reply.content = string.char(226, 128, 139)..format(argument:gsub('{file ([^}]+)}', function(s)
      if s:match('^https?://') then -- url
        files[#files + 1] = s
      else -- relative path
        files[#files + 1] = './user/'..s
      end
      return ''
    end):gsub('{rf(r?) ([^}]+)}', function(r, path)
      local f = const.getfiles('./user/'..path, r ~= 'r' and function(_, _, depth) return depth == 0 end)
      files[#files + 1] = f[math.random(#f)]
      return ''
    end):gsub('{nodelete}', function() nd = true return '' end))
  
    if #files > 0 then
      reply.files = files
    end
  
    args.message:reply(reply)
    if not nd then
      args.message:delete()
    end
  end
}