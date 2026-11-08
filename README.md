# Twintop Quality of Life

A grab-bag of quality-of-life (and silly) things for World of Warcraft. Tell your group a terrible joke, keep spirits up after a wipe, and dig into your talent data without leaving the game.

[![Release](https://img.shields.io/github/v/release/Twintop/TwintopQOL)](https://github.com/Twintop/TwintopQOL/releases)
[![Issues](https://img.shields.io/github/issues-raw/Twintop/TwintopQOL)](https://github.com/Twintop/TwintopQOL/issues)
[![MIT License](https://img.shields.io/github/license/Twintop/TwintopQOL)](https://github.com/Twintop/TwintopQOL/blob/main/LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-%23121011.svg?logo=github&logoColor=white)](https://github.com/Twintop/TwintopQOL/)

## Features

### Jokes

- Type `/tqol joke` to tell a joke in your group's chat: raid, instance, or party, whichever fits. Nothing is sent when you're not in a group.
- Name a channel to tell it there instead: `/tqol joke say`, `yell`, `emote`, `party`, `raid`, `rw` (raid warning), `instance`, `guild`, `officer`, or `whisper` and a name. The chat box's short forms work too (`s`, `y`, `p`, `g`, `w`, and so on). As in the chat box, party and raid go to instance chat in a group from the Dungeon Finder or Raid Finder.
- Ships with over 450 jokes, from groan-worthy puns to a few written just for WoW players.
- Wipe jokes: after a boss wipe, tells your group a joke to lighten the mood. Turn them on in the Jokes Configuration page, and choose which content they play in: open world, each dungeon and raid difficulty, Mythic+, delves, scenarios, battlegrounds, and arenas.
- By default, jokes don't repeat until every joke on your list has been told, even across sessions. Uncheck it in Configuration for pure random picks.

### Joke Editor

- Edit your joke list in game: add your own, fix the ones you don't like, and delete the ones that don't land.
- One joke per line, with line numbers and a highlight on the line you're editing.
- Reset to Defaults brings back the original list at any time.
- If you never customize your list, you get new jokes automatically as they're added in updates.

### General

- Ready check response: when you answer "ready" to a ready check, sends a message to the channel you pick: say (the default), yell, raid, raid warning, party, or emote. "Yes chef!" by default, or type your own. Turn it on in the General page.

### Flight Timer

Times every flight you take from a flight master, so the next time you fly that route you know how long is left.

- Hover a flight point on the flight map to see how long the flight there takes.
- The first time you fly a route, a bar counts up while it's timed. After that, the bar counts down the time left.
- A route you haven't flown yet gets an estimate, marked with ~, once you've flown each of its legs on its own.
- Each route keeps its fastest time, shared by all your characters. A route is timed by every stop it makes, so a character that knows fewer flight points, and flies a longer way to the same place, gets times of its own.
- Flights you leave early (by requesting an early landing, taking a summon, or porting into a battleground or dungeon) aren't recorded.
- On WoW Forever, flights with and without the Frequent Flier legacy perk are timed separately, so a respec doesn't throw either off. A route timed only one way is estimated for the other.
- Drag the bar to move it. On the Flight Timer page under General, turn off the bar or the tooltips (flights are timed while either is on), put the bar back where it started, or forget every recorded time.
- Make the bar your own on the same page: lock it in place (a locked bar lets clicks through), set its width and height, pick its texture and font from any LibSharedMedia status bar texture and font, set its font size, and choose its color, plus the color it shows while timing a new route. The bar shows a preview while the page is open.

### Talents

A sortable table of every talent in your active loadout, built for addon and WeakAura authors, theorycrafters, and the curious.

- Shows each talent's name, spell ID, entry ID, node ID, definition ID, icon ID, tree ID, ranks, and whether it's active.
- On Classic Era and The Burning Crusade Classic, lists every talent in your three talent trees instead: name, spell ID (of the rank you've learned), talent ID, tree, tab and index, icon ID, ranks, and whether it's learned.
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
| `/tqol joke <channel>` | Tells a joke in `say`, `yell`, `emote`, `party`, `raid`, `rw`, `instance`, `guild`, `officer`, or `whisper <name>` |
| `/tqol jokes` | Opens the Joke Editor |
| `/tqol talents` (or `/tqol df`) | Opens the Talents table |
| `/tqol news` | Opens the News window |
| `/tqol help` | Lists all commands in chat |

`/twintopqol` works anywhere `/tqol` does.

## Feedback

Found a bug or have an idea? Open an issue on [GitHub](https://github.com/Twintop/TwintopQOL/issues).

## License

Twintop Quality of Life is released under the [MIT License](LICENSE).
