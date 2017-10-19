local format = require('./libs/format')

return {
  name = 'e',
  call = function(self, argument, args)
    args.message:setContent(format(argument))
  end
}