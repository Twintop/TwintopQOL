<#
.SYNOPSIS
	Smoke-loads the addon under the stubbed-API harness and fails on real errors.

.DESCRIPTION
	Runs build\harness\load.lua three times: once through the login events; once with
	build\harness\drivers\pages.lua, which builds every main window page and runs every slash command; and once with
	build\harness\drivers\forever.lua, which loads the addon as the WoW Forever client.
	ERROR, SYNTAX, EVENT ERROR, DRIVER ERROR, and FAIL lines fail the run; TIMER ERROR lines are counted only.
	See build\harness\README.md.

.PARAMETER Lua
	Lua 5.1 interpreter to use. Defaults to "lua5.1" on the PATH.
#>
[CmdletBinding()]
param(
	[string]$Lua = "lua5.1"
)

$ErrorActionPreference = "Stop"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Split-Path -Parent $scriptDir
$harness = Join-Path $scriptDir "harness\load.lua"
$events = "ADDON_LOADED,PLAYER_LOGIN,PLAYER_ENTERING_WORLD"

if ($null -eq (Get-Command $Lua -ErrorAction SilentlyContinue)) {
	throw "Lua interpreter '$Lua' not found. Install Lua 5.1 or pass -Lua <path>."
}

$runs = @(
	[pscustomobject]@{ Name = "login"; Driver = "" },
	[pscustomobject]@{ Name = "pages"; Driver = (Join-Path $scriptDir "harness\drivers\pages.lua") },
	[pscustomobject]@{ Name = "forever"; Driver = (Join-Path $scriptDir "harness\drivers\forever.lua") }
)

$failed = $false
foreach ($run in $runs) {
	$env:TQOL_DRIVER = $run.Driver
	try {
		$output = & $Lua $harness $root "TwintopQOL.toc" 5 $events 2>&1 | Out-String
		$exitCode = $LASTEXITCODE
	} finally {
		Remove-Item Env:TQOL_DRIVER -ErrorAction SilentlyContinue
	}
	$lines = $output -split "`n"
	$real = ($lines | Where-Object { $_ -match "^(ERROR|SYNTAX|EVENT ERROR|DRIVER ERROR|FAIL)" }).Count
	$timers = ($lines | Where-Object { $_ -match "^TIMER ERROR" }).Count
	$loaded = ($lines | Where-Object { $_ -match "^Loaded " }) -join ""
	# No "Loaded" line means the harness never ran the TOC, which must not pass as clean.
	if ($real -gt 0 -or $exitCode -ne 0 -or $loaded -eq "") {
		$failed = $true
		Write-Host ("FAIL  {0}: {1}" -f $run.Name, $loaded.Trim())
		Write-Host ($lines | Where-Object { $_ -match "^(ERROR|SYNTAX|EVENT ERROR|DRIVER ERROR|FAIL)" -or $_ -match "^\s+" } | Select-Object -First 20 | Out-String)
	} else {
		Write-Host ("ok    {0}: {1} (deferred UI stub errors: {2})" -f $run.Name, $loaded.Trim(), $timers)
	}
}

if ($failed) { exit 1 }
Write-Host "smoke: the addon loads, bootstraps, and builds every page."

exit 0
