local _, TwintopQOL = ...
local L = TwintopQOL.Localization

-- General strings
L["TwintopQOL"] = "Twintop QOL"
L["ChatMessage"] = "|cFF00CCFFTQOL:|r %s"

-- Core.lua
L["SlashHelp"] = "Commands: |cFFFFFF00/tqol|r (open the Twintop QOL window), |cFFFFFF00joke|r (tell a joke now), |cFFFFFF00jokes|r (edit the joke list), |cFFFFFF00silly|r {on|off} (ready-check \"Yes chef!\" + wipe jokes), |cFFFFFF00talents|r / |cFFFFFF00df|r (talent list), |cFFFFFF00news|r (toggle news window), |cFFFFFF00help|r (this list)."
L["SillyModeEnabled"] = "Silly mode |cFF00FF00enabled|r."
L["SillyModeDisabled"] = "Silly mode |cFFFF0000disabled|r."
L["SillyModeUsage"] = "Usage: /tqol silly {on|off}"

-- Window.lua
L["FooterNews"] = "News"

-- News.lua
L["NewsHeader"] = "Twintop QOL Updates"
L["NewsCheckboxShowOnNewVersion"] = "Show on new version release"
L["NewsCheckboxShowOnNewVersionTooltip"] = "Show this update popup whenever a new version of Twintop QOL is released."
L["NewsHyperlinkIssueOnGitHub"] = "issue %s on GitHub"
L["UrlPopupText"] = "Here's a link to %s"

-- Silly.lua
L["SillyReadyCheckResponse"] = "Yes chef!"

-- JokesEditor.lua
L["JokesPageTitle"] = "Jokes"
L["JokesInstructions"] = "Enter |cFFFFCC00one joke per line|r. Blank lines are removed when you save. Click |cFFFFCC00Save|r to keep your changes; closing the window without saving discards them. Jokes longer than %d characters can't be sent in chat. Hold Shift and use the mouse wheel to scroll sideways."
L["JokesStatusCustom"] = "%d jokes (saved: custom list)"
L["JokesStatusDefault"] = "%d jokes (saved: default list)"
L["JokesStatusUnsaved"] = "%s  |cFFFF8000Unsaved changes|r"
L["JokesSave"] = "Save"
L["JokesResetToDefaults"] = "Reset to Defaults"
L["JokesResetConfirm"] = "Reset your joke list to the defaults? Your custom jokes will be lost."
L["JokesResetDone"] = "Joke list reset to the defaults."
L["JokesSaved"] = "Saved %d jokes."
L["JokesTooLongWarning"] = "|cFFFF8000Warning:|r %d jokes are longer than %d characters and can't be sent in chat."

-- Talents.lua
L["TalentsPageTitle"] = "Talents"
L["TalentsTitleWithLoadout"] = "Talents - %s"
L["TalentsTitleWithConfig"] = "%s |cFF888888(Config %d)|r"
L["TalentsColumnName"] = "Name"
L["TalentsColumnSpellId"] = "Spell ID"
L["TalentsColumnEntryId"] = "Entry ID"
L["TalentsColumnNodeId"] = "Node ID"
L["TalentsColumnDefinitionId"] = "Def ID"
L["TalentsColumnIconId"] = "Icon ID"
L["TalentsColumnTreeId"] = "Tree ID"
L["TalentsColumnRanks"] = "Ranks"
L["TalentsColumnStatus"] = "Status"
L["TalentsUnknownSpell"] = "?"
L["TalentsRanks"] = "%d/%d"
L["TalentsStatusActive"] = "Active"
L["TalentsStatusInactive"] = "Inactive"
L["TalentsRowCount"] = "%d talents (%d active)"
L["TalentsRefresh"] = "Refresh"
L["TalentsExport"] = "Export"
L["TalentsExportTitle"] = "Export (Ctrl+A, Ctrl+C to copy)"
L["TalentsShiftClickHint"] = "Shift-click a row to link the spell"
