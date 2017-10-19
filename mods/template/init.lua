return {
  name = "test",
  call = function(self, arg, args)
    args.message:reply({ embed = { title = "Nice test module bro :>"}})
  end,
  enable = function(self)
    print(self.name.." enable event")
  end,
  disable = function(self)
    print(self.name.." disable event")
  end
}