local log = require('./libs/log')

return {
  name = "test",
  call = function(self, arg, args)
    log(self.name.." module call event")
    args.message:reply({ embed = { title = "Nice test module bro :>"}})
  end,
  enable = function(self)
    log(self.name.." module enable event")
  end,
  disable = function(self)
    log(self.name.." module disable event")
  end
}