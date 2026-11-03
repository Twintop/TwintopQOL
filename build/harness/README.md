# Smoke-load harness

Loads the addon the way the client would (every file of the TOC and its XML includes, in order) under a
permissive stub of the WoW API, using a plain Lua 5.1 interpreter. It catches what a static checker cannot:
load-order errors, nil indexing at file scope, and errors in the `ADDON_LOADED` and `PLAYER_LOGIN` setup,
without launching the game. Copied from TwintopInsanityBar's harness; `stubs.lua` is kept close to its copy
there so fixes can move between them.

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

## Drivers

A driver is a Lua file returning hook functions, each called with a context table (`ns`, the addon table;
`stubs`; `addonName`; `addonDir`; `tocRel`; `classId`; `harnessDir`):

- `afterInstall`, after the stubs install and before the addon's files load;
- `afterLoad`, after the files load and before the events;
- `afterEvents`, after the events. A number it returns counts as that many failures.

| Driver | Run by | What it does |
| --- | --- | --- |
| `drivers\pages.lua` | `smoke.ps1` | Builds every main window page, clicks the Jokes Configuration checkboxes, runs every slash command, and fires a boss wipe with wipe jokes on. Prints `PASS` and `FAIL` lines. |
