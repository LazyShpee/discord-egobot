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
* `cw` - capitalize the first letter of each word
* `lo` - puts the text in lowercase
* `up` - puts the text in uppercase
* `md5` - produces a md5 hash

They can be combined with `+` and are treated from left to right.

Say (`//s`) has an additional operation: `file`, it adds on or multiple files from urls or from the `user` folder.

Example:
```//s {sb+ae Retarded spongebob aesthetics} normal text {cw sofa trigger machine}```

### Info

* `//info` - display a small embed with info about my creation, don't hesitate to share (^-^)b

### Test

* `//test` - just replies with `Nice test module BRO :ok_hand:`

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