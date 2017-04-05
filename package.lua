  return {
    name = "discord-egobot",
    version = "0.0.1",
    description = "A simple selfbot for Discord",
    tags = { "discord", "selfbot" },
    license = "MIT",
    author = { name = "LazyShpee", email = "comemureravaud@gmail.com" },
    homepage = "https://github.com/discord-egobot",
    dependencies = {
       "SinisterRectus/discordia",
       "SinisterRectus/sqlite3"
    },
    files = {
      "**.lua",
      "!test*"
    }
  }
  
