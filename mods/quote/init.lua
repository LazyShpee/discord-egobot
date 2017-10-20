return {
  name = 'quote',
  call = function(self, arg, args)
    local ids = {}
    arg:gsub('(%d+)', function(id)
      ids[#ids + 1] = id
    end)
    
    local channel = args.message.channel
    if ids[2] then channel = args.message.client:getChannel(ids[2]) end
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
            if args.message.guild ~= channel.guild then
              embed.footer = {
                text = "On " .. channel.guild.name .. " | #" .. channel.name,
                icon_url = channel.guild.iconUrl,
              }
            else
              embed.footer = {
                text = "On #" .. channel.name,
              }
            end
          end

          args.message:reply({embed = embed})
          return
        end
      end
    end
  end
  }