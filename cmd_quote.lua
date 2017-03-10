local req,_,shared,client  = ...
local pp = req('pretty-print')
local log = require('logger')
local sql = req("sqlite3")

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

local _RAWEMBED = {
   name = 'rawembed',
   call = function(m, c, a)
      local mid, cid = a:match('([0-9]+) *([0-9]*)')
      if #mid > 0 then
	 local channel = m.channel
	 client:getChannel("id", cid)
	 for msg in channel:getMessageHistoryAround({_id = mid}, 1) do
	    if msg.id == mid then
	       m:reply('```lua\n'..pp.strip(pp.dump(msg.embed))..'\n'..pp.strip(pp.dump(msg.attachments))..'```')
	       return
	    end
	 end
      end
   end
}

local db = shared.db

db "CREATE TABLE IF NOT EXISTS saved_messages(gid NUM, cid NUM, mid NUM, uid NUM, uname TEXT, content TEXT, embed TEXT, attachment TEXT, created NUM)"

local _SAVE = {
   name = 'save',
   call = function(m, c, a)
      if #a == 0 then return end
      for msg in m.channel:getMessageHistoryAround({_id = a}, 1) do
	 if msg.id == a then
	    local gid, cid, mid, uid, uname, content, embed, attachments, created = m.channel.guild.id, msg.channel.id, msg.id, msg.author.id, msg.author.username, msg.content, msg.embed, msg.attachments, msg.createdAt
	    db("INSERT INTO saved_messages VALUES("..gid..", "..cid..", "..mid..", "..uid..", '"..uname:gsub("'", "''").."', '"..content:gsub("'", "''").."', \""..pp.strip(pp.dump(embed)).."\", \""..pp.strip(pp.dump(attachments)).."\", "..created..")")
	    m.content = '`Saved '..a..'`'
	    break
	 end
      end
   end
}

local _LOAD = {
   name = 'load',
   call = function(m, c, a)
      local t = db:exec("SELECT * FROM saved_messages WHERE uid = "..a)
      print(pp.dump(t))
   end
}

return _QUOTE, _RAWEMBED, _SAVE, _LOAD
