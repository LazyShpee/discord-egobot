local emoji = require("./libs/emojis")
local allowed = { prefix = true }

return {
  name = 'config',
  call = function(self, arg, args)
    local var, val = arg:match('^(%w+)%s*(.*)$')
    if #var > 0 and allowed[var] then
      if #val > 0 then
        db.config[var] = val
        db:save('config')
        args.message:reply({ embed = {
          title = emoji.heavy_check_mark..' **'..var..'** set to `'..val..'`'
        }})
      else
        args.message:reply({ embed = {
          fields = {
            {
              name = var,
              value = '`'..db.config[var]..'`'
            }
          }
        }})
      end
    end
  end
}