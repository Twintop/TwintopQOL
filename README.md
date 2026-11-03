# Twintop Quality of Life

A grab-bag of quality-of-life (and silly) things for World of Warcraft. Tell your group a terrible joke, keep spirits up after a wipe, and dig into your talent data without leaving the game.

[![Release](https://img.shields.io/github/v/release/Twintop/TwintopQOL)](https://github.com/Twintop/TwintopQOL/releases)
[![Issues](https://img.shields.io/github/issues-raw/Twintop/TwintopQOL)](https://github.com/Twintop/TwintopQOL/issues)
[![MIT License](https://img.shields.io/github/license/Twintop/TwintopQOL)](https://github.com/Twintop/TwintopQOL/blob/main/LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-%23121011.svg?logo=github&logoColor=white)](https://github.com/Twintop/TwintopQOL/)

## Features

### Jokes

- Type `/tqol joke` to tell a joke in your group's chat: raid, instance, or party, whichever fits. Nothing is sent when you're not in a group.
- Ships with over 500 jokes, from groan-worthy puns to a few written just for WoW players.
- Wipe jokes: after a boss wipe, tells your group a joke to lighten the mood. Turn them on in the Jokes Configuration page, and choose which content they play in: open world, each dungeon and raid difficulty, Mythic+, delves, scenarios, battlegrounds, and arenas.
- By default, jokes don't repeat until every joke on your list has been told, even across sessions. Uncheck it in Configuration for pure random picks.

### Joke Editor

- Edit your joke list in game: add your own, fix the ones you don't like, and delete the ones that don't land.
- One joke per line, with line numbers and a highlight on the line you're editing.
- Reset to Defaults brings back the original list at any time.
- If you never customize your list, you get new jokes automatically as they're added in updates.

### General

- Ready check response: when you answer "ready" to a ready check, sends a message to the channel you pick: say (the default), yell, raid, raid warning, party, or emote. "Yes chef!" by default, or type your own. Turn it on in the General page.

### Talents

A sortable table of every talent in your active loadout, built for addon and WeakAura authors, theorycrafters, and the curious.

- Shows each talent's name, spell ID, entry ID, node ID, definition ID, icon ID, tree ID, ranks, and whether it's active.
- Click a column header to sort by it.
- Hover a row for the spell tooltip, or shift-click to link the spell in chat.
- Export the whole table as tab-separated text, ready to paste into a spreadsheet.
- Updates automatically when you change talents or specialization.

### News

A popup shows what's new whenever a new version is released. You can turn it off, and reopen it any time with `/tqol news`.

## Commands

| Command | What it does |
| --- | --- |
| `/tqol` | Opens or closes the Twintop QOL window |
| `/tqol joke` | Tells a joke in group chat |
| `/tqol jokes` | Opens the Joke Editor |
| `/tqol talents` (or `/tqol df`) | Opens the Talents table |
| `/tqol news` | Opens the News window |
| `/tqol help` | Lists all commands in chat |

`/twintopqol` works anywhere `/tqol` does.

## Feedback

Found a bug or have an idea? Open an issue on [GitHub](https://github.com/Twintop/TwintopQOL/issues).

## License

Twintop Quality of Life is released under the [MIT License](LICENSE).
