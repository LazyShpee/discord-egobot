local const = require('./libs/const')
return {
  name = 'info',
  call = function(self, _, args)
    local embed = {
      author = {
        name = args.message.author.name.."'s selfbot",
        icon_url = args.message.author.avatarUrl
      },
      description = "Egobot-rw created by [LazyShpee](https://github.com/LazyShpee/)\nhttps://github.com/LazyShpee/discord-egobot/",
      type = 'video',
      --color = 99219,
      timestamp = const.startTime
    }
    
    local footer = {}
    if const.hostname or const.version then
      if const.hostname then table.insert(footer, 'On '..const.hostname) end
      if const.version then table.insert(footer, const.version) end
      embed.footer = {text = table.concat(footer, ' | ')}
    end
    
    args.message:reply({embed = embed})
    args.message:delete()
  end
}