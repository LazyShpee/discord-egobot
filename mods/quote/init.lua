return {
  name = 'quote',
  call = function(self, arg, args)
    local ids = {}
    arg:gsub('(%d+)', function(id)
      ids[#ids + 1] = id
    end)
    
    local channel = args.message.channel
    local user = nil
    if ids[2] then
      channel = args.message.client:getChannel(ids[2])
      if not channel then
        user = args.message.client:getUser(ids[2])
        if user then channel = user:getPrivateChannel() end
      end
    end
    if not ids[1] then return end
    
    if channel then
      for id, msg in pairs(channel:getMessagesAround(ids[1], 1)) do
        if id == ids[1] then
          local embed = {
            description = msg.content,
            author = {
              icon_url = msg.author.avatarURL,
              name = msg.author.name
            },
            color = 6673764,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%S', msg.createdAt)
          }
          
          -- Courtesy of Siapran
          if args.message.channel ~= channel then
            if channel.guild and args.message.guild ~= channel.guild then
              embed.footer = {
                text = "On " .. channel.guild.name .. " | #" .. channel.name,
                icon_url = channel.guild.iconUrl,
              }
            elseif channel.guild then
              embed.footer = {
                text = "On #" .. channel.name,
              }
            else
              embed.footer = {
                text = "@"..channel.name
              }
            end
          end

          args.message:reply({embed = embed})
          args.message:delete()
          return
        end
      end
    end
  end
  }