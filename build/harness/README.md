# Smoke-load harness

Loads the addon the way the client would (every file of the TOC and its XML includes, in order) under a
permissive stub of the WoW API, using a plain Lua 5.1 interpreter. It catches what a static checker cannot:
load-order errors, nil indexing at file scope, and errors in the `ADDON_LOADED` and `PLAYER_LOGIN` setup,
without launching the game. Copied from TwintopInsanityBar's harness; `stubs.lua` is kept close to its copy
there so fixes can move between them.

The stubs fake LibSharedMedia in full, so `load.lua` skips it and CallbackHandler, which it needs, as
TwintopInsanityBar's harness skips every library. Loading the real ones over the fake would leave its
`LibSharedMedia_Registered` callbacks never firing.

Frames and Blizzard APIs are stubs, so code that leans on real widget behavior can hit a stub it cannot
emulate. Those show up as `TIMER ERROR` lines and are informational; `ERROR`, `SYNTAX`, `EVENT ERROR`,
`DRIVER ERROR`, and `FAIL` lines are real.

## Usage

```
lua5.1 build/harness/load.lua <addonDir> <tocRelPath> [classId] [events]

lua5.1 build/harness/load.lua . TwintopQOL.toc 5 ADDON_LOADED,PLAYER_LOGIN
```

`events` is a comma-separated list fired in order after all files load. An event's arguments follow a colon,
separated by semicolons: `ENCOUNTER_END:1;Boss;16;20;0`. `C_Timer.After` callbacks queued by a handler run
right after it.

Environment variables:

- `TQOL_SAVED=<file>`: a WoW SavedVariables file to load before the addon. Your real
  `WTF\Account\<name>\SavedVariables\TwintopQOL.lua` works as-is.
- `TQOL_DRIVER=<file>`: a driver, below.
- `TQOL_INTERFACE=<number>`: the client to load as, by interface number (`11509`, `16001`, `20506`). The TOC lists
  every flavor's, and the stubs otherwise follow its first, retail.

## Drivers

A driver is a Lua file returning hook functions, each called with a context table (`ns`, the addon table;
`stubs`; `addonName`; `addonDir`; `tocRel`; `classId`; `harnessDir`):

- `afterInstall`, after the stubs install and before the addon's files load;
- `afterLoad`, after the files load and before the events;
- `afterEvents`, after the events. A number it returns counts as that many failures.

| Driver | Run by | What it does |
| --- | --- | --- |
| `drivers\pages.lua` | `smoke.ps1` | Builds every main window page, clicks the Jokes Configuration checkboxes, runs every slash command, and fires a boss wipe with wipe jokes on. Flies the flight timer through a new route, timed routes (keeping the fastest), a route with a stop (estimated from its legs first), an early landing, a flight never taken, a loading screen, and the Flight Timer page's settings (the bar off, the tooltips off, and both), and checks the flight map's tooltips as it goes. Then sets the timer bar's lock, size, texture and font (each from its dropdown, and one registered late), font size, and colors (through the color picker's callbacks), watching its preview. Prints `PASS` and `FAIL` lines. |
| `drivers\forever.lua` | `smoke.ps1` | Loads the addon as the WoW Forever client (`16001`, `WOW_PROJECT_CAMELOT`): checks the Jokes content types are cut to the ones Forever has, the Talents page falls back to the dual spec group's config, the flight timer keeps Frequent Flier times apart and estimates across a respec, and every page builds. Prints `PASS` and `FAIL` lines. |
| `drivers\classic.lua` | `smoke.ps1` | Loads the addon as the Classic Era (`11509`) or The Burning Crusade Classic (`20506`) client: checks the flavor flags and that client's rank spell table, that every page builds, that the Talents page reads the talent tabs, shows each talent's learned (or rank 1) spell, exports the tab columns, and shows the talent tooltip, and that the flight timer times a flight with a stop and shows it in the flight master window's tooltip. Prints `PASS` and `FAIL` lines. |

The drivers that take flights share `taxi.lua`, required as `taxi`: a fake flight master with three flight points (the
third reached through the second), a clock it controls in place of `GetTime`, and `Fly`, which takes a flight and steps
the flight timer's `OnUpdate` through takeoff, every second of the flight, and landing. It also stands in for both
flight maps' flight point tooltips: `HoverButton` hovers a button of the Classic flight master window, and `HoverPin` a
pin of the retail flight map, once `LoadFlightMap` has loaded it the way the client loads it on demand. Status bars keep
the color and texture they're given, and their texts the font, which the stubs drop, so `GetBarColor`, `GetBarTexture`, and
`GetBarFont` can read the bar's look.
