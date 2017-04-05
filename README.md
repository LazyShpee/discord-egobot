# Egobot

This is a simple Discord selfbot written in Lua

## Getting Started

### Prerequisites

You will need to get [luvit](http://luvit.io/), lit and [sqlite3](https://sqlite.org/download.html) as a dynamic library in order to run Egobot, recommended platform: Linux

### Installing

Clone this repo

```
git clone git@github.com:LazyShpee/discord-egobot.git && cd discord-egobot
```

Let lit install it's dependencies

```
lit install
```

End with an example of getting some data out of the system or using it for a little demo

## Running Egobot

To run Egobot, you will need to get your Discord token (google is your friend, methods may vary)

```
luvit egobot.lua DISCORD_TOKEN [WEBUI PASSWORD]
```

To launch with Web UI, enter a WEBUI PASSWORD and access the interface with http://localhost:1234/index.html?WEBUI PASSWORD

## Features

* WebUI (Indev, but stable and usable)

## ToDo / Planned (?) Features

* Local webUI for config and more
* Per command configuration

## Author

* **Côme MURE-RAVAUD** - [LazyShpee](https://github.com/LazyShpee)

See also the list of [contributors](https://github.com/LazyShpee/discord-egobot/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE) file for details

## Acknowledgments and thanks

* SinisterRectus for [Discordia](https://github.com/SinisterRectus/Discordia), a Discord luvit API
* Inspired by Siapran's [selfbot](https://github.com/Siapran/discord-selfbot/)
* kikito for [md5.lua](https://github.com/kikito/md5.lua)
* If I've missed anything/anyone feel free to contact me so I can correct this