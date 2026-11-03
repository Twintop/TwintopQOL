local _, TwintopQOL = ...

-- Changelog shown by the News window (News.lua renders it). Markdown; newest release first.
TwintopQOL.NewsContent = [====[

# 1.0.1-release (2026-11-04)
## Jokes

- Run copyedit over the jokes list to fix typos, grammar, punctuation, and remove duplicates and near-duplicates. The list is now ~450 jokes, down from ~500.
- If you've customized your joke list, you'll keep it as is. To get the updated jokes, reset your list to the defaults in the Joke Editor.

---

# 1.0.0-release (2026-11-03)

The first public release of Twintop QOL: a grab-bag of quality-of-life (and silly) things for World of Warcraft.

## General

- Type `/tqol` to open the Twintop QOL window, which holds every page and setting. It's also listed under Options > AddOns.
- Ready check response: when you answer "ready" to a ready check, sends a message to the channel you pick: say (the default), yell, raid, raid warning, party, or emote. "Yes chef!" by default, or type your own. Turn it on in the General page.
- Works on both retail and WoW Forever.

## Jokes

- Type `/tqol joke` to tell a joke in your group's chat: raid, instance, or party, whichever fits. Nothing is sent when you're not in a group.
- Ships with over 500 jokes, from groan-worthy terrible dad joke puns to a few written just for WoW players.
- Wipe jokes: after a boss wipe, tells your group a joke to lighten the mood. Turn them on in the Jokes Configuration page, and choose which content they play in: open world, each dungeon and raid difficulty, Mythic+, delves, scenarios, battlegrounds, and arenas.
- By default, jokes don't repeat until every joke on your list has been told, even across sessions. Uncheck it in Configuration for pure random picks.

## Joke Editor

- Type `/tqol jokes` to edit your joke list in game: add your own, fix the ones you don't like, and delete the ones that don't land.
- One joke per line, with line numbers and a highlight on the line you're editing.
- Reset to Defaults brings back the original list at any time.
- If you never customize your list, you get new jokes automatically as they're added in updates.

## Talents

- Type `/tqol talents` (or `/tqol df`) for a sortable table of every talent in your active loadout, built for addon and WeakAura authors, theorycrafters, and the curious.
- Shows each talent's name, spell ID, entry ID, node ID, definition ID, icon ID, tree ID, ranks, and whether it's active.
- Click a column header to sort by it. Hover a row for the spell tooltip, or shift-click to link the spell in chat.
- Export the whole table as tab-separated text, ready to paste into a spreadsheet.
- Updates automatically when you change talents, specialization, or dual spec.

## News

- This window: shows what's new whenever a new version is released. You can turn it off, and reopen it any time with `/tqol news`.

]====]
