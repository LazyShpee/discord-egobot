local req,_,shared,client  = ...
local pp = req('pretty-print')
local log = require('utils.logger')
local sql = req("sqlite3")

local _VQUOTE = {
   name = 'vquote',
   call = function(m, c, a)
      local user, text, footer = a:match('^([^|]+)|([^|]+)|?(.-)$')
      if not user or #user == 0 or not text or #text == 0 then return end
      local ans = {
	 embed = {
	    description = text,
	    color = 7493255,
	    author = {
	       name = user
	    }
	 }
      }
      if #footer > 0 then
	 ans.embed.footer = {
	    text = footer
	 }
      else
	 ans.embed.timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
      end
      m:reply(ans)
      m:delete()
   end,
   display_name = 'Quoter',
   usage = '<name>|<text>[| footer text]',
   author = 'LazyShpee',
   description = [[This makes an embed quote like reply
If footer is empty, uses the date and time]]
}

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
   end,
   author = 'LazyShpee',
   usage = '<message id> [channel id] /[pattern to apply to quote]/ [answer to quote]',
   display_name = 'Discord Quoter',
   description = [[Quotes `message id` as an embed reply
Channel id is only needed is the message isn't in the channel
Answer to quote is an extra message sent right after the quote, as an answer]]
}

local _RAWEMBED = {
   name = 'rawembed',
   call = function(m, c, a)
      local mid, cid = a:match('([0-9]+) *([0-9]*)')
      if #mid > 0 then
	 local channel = m.channel
	 if #cid > 0 then
	    channel = client:getChannel("id", cid)
	 end
	 if not channel then return end
	 for msg in channel:getMessageHistoryAround({_id = mid}, 1) do
	    if msg.id == mid then
	       m:reply('```lua\n'..pp.strip(pp.dump(msg.embed))..'\n'..pp.strip(pp.dump(msg.attachments))..'```')
	       return
	    end
	 end
      end
   end,
   usage = '<message id> [channel id]',
   description = 'Shows raw embed and attachements of a message for debug purposes',
   author = 'LazyShpee',
   display_name = 'raw view'
}

local db = shared.db

db "CREATE TABLE IF NOT EXISTS saved_messages(gid NUM, gim TEXT, cid NUM, mid NUM, uid NUM, gname TEXT, cname TEXT, uav TEXT, uname TEXT, content TEXT, embed TEXT, attachment TEXT, created NUM, tags TEXT)"

local _SAVE = {
   name = 'save',
   call = function(m, c, a)
      if #a == 0 then return end
      local id, tags = a:match("^([0-9]+) *(.*)$")
      for msg in m.channel:getMessageHistoryAround({_id = id}, 1) do
	 if msg.id == id then
	    local gid, gim, cid, mid, uid, gname, cname, uav, uname, content, embed, attachments, created = m.channel.guild.id, msg.channel.guild.iconUrl, msg.channel.id, msg.id, msg.author.id, msg.channel.guild.name, msg.channel.name, msg.author.avatarUrl, msg.author.username, msg.content, msg.embed, msg.attachments, msg.createdAt
	    db("INSERT INTO saved_messages VALUES("..gid..", '"..gim:gsub("'", "''").."', "..cid..", "..mid..", "..uid..", '"..gname:gsub("'", "''").."', '"..cname:gsub("'", "''").."', '"..uav:gsub("'", "''").."', '"..uname:gsub("'", "''").."', '"..content:gsub("'", "''").."', \""..pp.strip(pp.dump(embed)).."\", \""..pp.strip(pp.dump(attachments)).."\", "..created..", '"..tags:gsub("'", "''").."')")
	    m.content = '`Saved '..a..'`'
	    break
	 end
      end
   end
}

local _LOAD = {
   name = 'load',
   call = function(m, c, a)
      local t = db:exec("SELECT * FROM saved_messages WHERE "..a..";")
      if t and #t > 0 then
	 local r = math.random(1, #t.mid)
    local res = {
      embed = {
        description = t.content[r],
        color = 3492471,
        timestamp =  os.date('!%Y-%m-%dT%H:%M:%S', t.created[r]),
        author = {
          name = t.uname[r],
          url = "http://"..tostring(t.mid[r])..".mid",
          icon_url = t.uav[r]
        },
        footer = {
          icon_url = t.gim[r],
          text = "On "..t.gname[r].." | #"..t.cname[r]
        }
      }
	 }
	 local attachment = loadstring('return ('..t.attachment[r]..')')()
	 if attachment and #attachment > 0 then
	    res.embed.image = {url = attachment[1].url}
	 end
	 m:reply(res)
      end
      m:delete()
   end
}

return _QUOTE, _RAWEMBED, _SAVE, _LOAD, _VQUOTE
