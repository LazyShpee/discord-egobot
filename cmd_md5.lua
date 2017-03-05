local log = require('logger')
local md5 = require('md5')

local _MD5 = {
   name = 'md5',
   call = 
   function(msg, cmd, arg --[[, client]])
      if #arg == 0 then return end
      msg.content = '`md5("'..arg..'") = '..(md5.sumhexa(arg))..'`'
   end,
   usage = '${prefix}${cmd} <string to hash>',
   description = 'This is a simple MD5 hashing command',
   author = 'LazyShpee'
}

return _MD5