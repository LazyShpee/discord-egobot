print("Test module loaded")

return {
  name = 'test',
  enable = function()
    print('Test module enabled')
  end,
  call = function(self, argument, args)
    args.message:reply('Nice test module BRO 👌')
    args.message:delete()
  end
}