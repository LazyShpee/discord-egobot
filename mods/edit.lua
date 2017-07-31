local format = require('./libs/format')

return {
  name = 'e',
  call = function(self, argument, args)
    args.message.content = format(argument)
  end
}