local _, _, _, client = ...
local version = io.popen('git show-ref --head --abbrev --hash'):read()
local hostname = io.popen('hostname'):read()
local start_time = os.date('!%Y-%m-%dT%H:%M:%S')

local _INFO = {
   name = 'info',
   call = function (msg)
      local answer = {
	 description = "https://github.com/LazyShpee/discord-egobot\nMade by <@87574389666611200>",
	 color = 2344332,
	 timestamp = start_time,
	 author = {
	    name = client.user.username.."'s self-bot",
	    icon_url = client.user.avatarUrl
	 }
      }
      local footer = {}
      if hostname or version then
	 if hostname then table.insert(footer, 'On '..hostname) end
	 if version then table.insert(footer, version) end
	 answer.footer = {text = table.concat(footer, ' | ')}
      end
      msg:delete()
      msg:reply({embed = answer})
   end
}

return _INFO
