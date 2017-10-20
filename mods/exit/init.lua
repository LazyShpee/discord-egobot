local num = {
  update = 42,
  restart = 43,
  stop = 0
}

local default = num.stop

return {
  name = 'exit',
  call = function(self, arg, args)
    local code = num[arg] or default
    client:stop()
    os.exit(code)
  end
}