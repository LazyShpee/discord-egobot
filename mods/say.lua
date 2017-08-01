local format = require('./libs/format')

return {
  name = 's',
  call = function(self, argument, args)
  
    local reply = {}
    local files = {}

    reply.content = format(argument:gsub('{file ([^}]+)}', function(s)
      if s:match('^https?://') then -- url
        files[#files + 1] = s
      else -- relative path
        files[#files + 1] = './user/'..s
      end
      return ''
    end))
  
    if #files > 0 then
      reply.files = files
    end
  
    args.message:reply(reply)
    args.message:delete()
  end
}