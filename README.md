# Egobot-rw

This is a simple Discord selfbot written in Lua
This is the rewrite of my original egobot, I decided to restart from scratch to:
* Remove its dependency to sqlite3
* Have a better control over modules
* Make everything be module, from aliases to config interface

## Getting Started

### Prerequisites

You will need to get [luvit](http://luvit.io/) and lit to run Egobot, recommended platform: Linux

### Installing

Clone this repo

```
git clone git@github.com:LazyShpee/discord-egobot.git && cd discord-egobot
```

Let lit install it's dependencies

```
lit install
```

## Running Egobot

To run Egobot, you will need to get your Discord token (google is your friend, methods may vary)

```
luvit egobot.lua --token DISCORD_TOKEN
```

## Current Features/Modules

Examples will be using the default prefix `//`

### Say and Edit

* `//s <text>` - deletes the command message and replies for formatted text
* `//e <text>` - edits the command message and changes it to formatted text

Text can plain text with a combination of one or more curly braces operations formatted as follow:
`{operation_name text}`

If `operation_name` is known by the formatter it will replace the curly braces operation by formatted text as follow:
* `ae` - converts ascii characters to fullwidth
* `sb` - retarded spongebob talk
* `sp` - adds spaces in between each characters (including spaces)
* `ro` - randomly shuffles the words
* `cw` - Capitalize The First Letter Of Each Word
* `lo` - puts the text in lowercase
* `up` - PUTS THE TEXT IN UPPERCASE
* `md5` - produces a md5 hash
* `txt` - outputs the content of a file
* `rl` - outputs a random line from a file

They can be combined with `+` and are treated from left to right.

Say (`//s`) has additional operations, root is the `user` folder, those cannot be combined:

* `file` - attaches a file from url or path provided
* `rf` and `rfr` - attaches a random file from path, `rfr` includes subfolders
* `nodelete` - takes no arguments, prevent the command message deletion
* `rlu` - takes a random line from a file and uploads it as a `file` would

Example:
```//s {sb+ae Retarded spongebob aesthetics} normal text {cw sofa trigger machine}```

### Alias

`//alias <action> [alias] [value]`

Actions are one of:

* `set <alias> <value>` - creates or changes an alias
* `delete <alias>` - deletes an alias
* `params <alias> [inline|before|after]` - sets if arguments are passed on, `inline` replaces `%s` by the argument
* `save` and `reload` - saves and reload aliases to/from config
* `list` - Lists aliases
* `show <alias>` - shows an alias value and its configuration

### Eval

Eval some lua code in the bot's env - `//eval lua code`.

Additional variables:

* `client` - the bot's object
* `message` - command message object
* `channel` - channel object of command message
* `guild` - guild object of command message

### Info

* `//info` - display a small embed with info about my creation, don't hesitate to share (^-^)b

### Test

* `//test` - just replies with `Nice test module BRO :ok_hand:`

## TODO (order is arbitrary)

To be done in a near future/upcomming commits

* TODO :>

To be done some other time

* Web UI for config and administering
* Alias backup and restore

## Author

* ***REMOVED*** [LazyShpee](https://github.com/LazyShpee)

See also the list of [contributors](https://github.com/LazyShpee/discord-egobot/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE) file for details

## Acknowledgments and thanks

* SinisterRectus for [Discordia](https://github.com/SinisterRectus/Discordia), a Discord luvit API
* Inspired by Siapran's [selfbot](https://github.com/Siapran/discord-selfbot/)
* kikito for [md5.lua](https://github.com/kikito/md5.lua)
* If I've missed anything/anyone feel free to contact me so I can correct this