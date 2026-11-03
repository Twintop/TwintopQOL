param(
    [string]$Path = "Localization/enUS.lua"
)

$ErrorActionPreference = "Stop"

function Fail($message) {
    Write-Error $message
    exit 1
}

$git = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $git) {
    Fail "git is required to validate localization append-only changes."
}

$baseLines = & git show "HEAD:$Path" 2>$null
if ($LASTEXITCODE -ne 0) {
    Fail "Unable to read HEAD:$Path. Run this from the repository root with a valid git history."
}

$baseLineCount = @($baseLines).Count
$diffLines = & git diff --unified=0 -- $Path
if ($LASTEXITCODE -ne 0) {
    Fail "Unable to read git diff for $Path."
}

if ($diffLines.Count -eq 0) {
    Write-Output "No enUS localization changes detected."
    exit 0
}

$hunkOldStart = $null
$hunkOldCount = $null
$violations = New-Object System.Collections.Generic.List[string]

foreach ($line in $diffLines) {
    if ($line -match '^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@') {
        $hunkOldStart = [int]$Matches[1]
        if ($Matches[2]) {
            $hunkOldCount = [int]$Matches[2]
        } else {
            $hunkOldCount = 1
        }
        continue
    }

    if ($line -match '^\+L\["') {
        $hunkOldEnd = $hunkOldStart + [Math]::Max($hunkOldCount, 1) - 1
        $isAppendAtEnd = ($hunkOldEnd -ge $baseLineCount)
        if (-not $isAppendAtEnd) {
            $violations.Add($line.Substring(1))
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Error "Localization append-only violation in $Path. New active L[...] entries must be appended after the last line of the file."
    foreach ($violation in $violations) {
        Write-Error "  $violation"
    }
    exit 1
}

Write-Output "enUS localization additions are append-only."