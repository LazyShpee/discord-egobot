local log = require('logger')

local _QUOTE = {
   name = 'quote',
   call = function(m, c, a)
      local id, pattern, reply = {}, '.*', ''
      a = a..' '
      a:gsub('(%d+) ',
	     function(m)
		table.insert(id, m)
		return ''
      end):gsub('/([^/]+)/ ',
		function(m)
		   pattern = m
		   return ''
	       end):gsub('(.*) ',
			 function(m)
			    reply = m
			    return ''
			end)
      
      local channel = m.channel
      if #id >= 2 then channel = client:getChannel("id", id[2]) end
      if #id == 0 then return end -- Requires at least one id
      if channel then
	 for msg in channel:getMessageHistoryAround({_id = id[1]}, 1) do
	    if msg and msg.id == id[1] then
	       
	       local mq = table.concat({msg.content:match(pattern)}, ' ')
	       if #mq == 0 then break end
	       
	       local resp = {embed = {
				description = mq,
				color = 6673764,
				author = {
				   name = msg.author.username,
				   icon_url = msg.author.avatarUrl
				},
				timestamp = os.date('!%Y-%m-%dT%H:%M:%S', msg.createdAt)
			    }}
	       
	       -- Courtesy of Siapran
	       if m.channel ~= channel then
		  if m.guild ~= channel.guild then
		     resp.embed.footer = {
			text = "On " .. channel.guild.name .. " | #" .. channel.name,
			icon_url = channel.guild.iconUrl,
		     }
		  else
		     resp.embed.footer = {
			text = "On #" .. channel.name,
		     }
		  end
	       end
	       
	       m:reply(resp)
	       if reply and #reply > 0 then m:reply(reply) end
	       log('Quoted '..msg.author.username..' ['..id[1]..'] '..pattern, nil, 'quote')
	       break
	    end
	 end
      end
      m:delete()
   end

}

return _QUOTE
