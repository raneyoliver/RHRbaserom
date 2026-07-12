# Load a savestate into Mesen.
#
# RELIABLE: -Relaunch closes Mesen and opens the .mss file alone (Mesen loads
#           the embedded ROM + state). Restart MCP after: start-mcp.ps1 + Mesen Start.
#
# IN-SESSION: Press F1 in Mesen (Load State Slot 1) — hot CLI load is unreliable.
#
# Usage:
#   .\load-savestate.ps1 -Slot 1 -Relaunch
#   .\load-savestate.ps1 -SaveStatePath "C:\path\to\state.mss" -Relaunch

param(
    [int]$Slot = 0,
    [string]$SaveState = "",
    [string]$SaveStatePath = "",
    [switch]$Relaunch
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$mesenExe = Join-Path $repoRoot "tools\mesen2-expanded\Mesen.exe"

if (-not (Test-Path $mesenExe)) {
    throw "Mesen not found at $mesenExe"
}

if ($Slot -gt 0 -and -not $SaveStatePath) {
    $mesenData = Join-Path $env:USERPROFILE "Documents\Mesen2\SaveStates"
    $candidate = Join-Path $mesenData "RHRv5_$Slot.mss"
    if (-not (Test-Path $candidate)) {
        throw "Slot $Slot not found: $candidate"
    }
    $SaveStatePath = $candidate
}

if ($SaveState -and -not $SaveStatePath) {
    $manifest = Join-Path $repoRoot "tools\test\savestates\manifest.toml"
    $text = Get-Content $manifest -Raw
    $pattern = "(?m)^\[$([regex]::Escape($SaveState))\]\s*\r?\nfile\s*=\s*`"([^`"]+)`""
    if ($text -notmatch $pattern) {
        throw "Unknown savestate '$SaveState' in manifest.toml"
    }
    $SaveStatePath = Join-Path $repoRoot $Matches[1]
}

if (-not $SaveStatePath) {
    throw "Provide -Slot <n>, -SaveState <name>, or -SaveStatePath <path>"
}

if (-not (Test-Path $SaveStatePath)) {
    throw "Savestate file not found: $SaveStatePath"
}

$resolved = (Resolve-Path $SaveStatePath).Path

if ($Relaunch) {
    Write-Host "Relaunching Mesen with savestate only (loads embedded ROM + state):"
    Write-Host "  $resolved"
    Get-Process -Name "Mesen" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    # Pass ONLY the .mss — Mesen loads the ROM path stored inside the savestate.
    Start-Process -FilePath $mesenExe -ArgumentList "`"$resolved`""
    Write-Host ""
    Write-Host "After Mesen opens:"
    Write-Host "  1. tools/test/mesen/start-mcp.ps1"
    Write-Host "  2. Tools -> MCP Server -> Start"
    exit 0
}

Write-Host "Hot-loading via single-instance (often does NOT apply visually):"
Write-Host "  $resolved"
Write-Host ""
Write-Host "If nothing changes on screen, either:"
Write-Host "  - Press F1 in Mesen (Load State Slot 1), or"
Write-Host "  - Run: .\load-savestate.ps1 -Slot $Slot -Relaunch"
Start-Process -FilePath $mesenExe -ArgumentList "`"$resolved`""
Write-Host "Done."
