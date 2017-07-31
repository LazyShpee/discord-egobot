local format = require('./libs/format')

return {
  name = 's',
  call = function(self, argument, args)
    args.message:reply(format(argument))
    args.message:delete()
  end
}