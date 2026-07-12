# Launch Mesen2-Expanded with the built ROM (and optional savestate / automation).
# Usage:
#   .\launch.ps1
#   .\launch.ps1 -Automation                    # ROM + automation.lua for run-session.ps1
#   .\run-session.ps1 -Slot 1 -WalkRight -Frames 5   # full automated test (preferred)

param(
    [string]$RomPath = "",
    [string]$SaveState = "",
    [string]$SaveStatePath = "",
    [switch]$Automation
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$mesenExe = Join-Path $repoRoot "tools\mesen2-expanded\Mesen.exe"

if (-not (Test-Path $mesenExe)) {
    Write-Host "Mesen not found. Run: powershell -File tools/test/mesen/download-mesen-expanded.ps1"
    exit 1
}

if (-not $RomPath) {
    $RomPath = Join-Path $repoRoot "workspace\RHRv5.smc"
}

if (-not (Test-Path $RomPath)) {
    throw "ROM not found: $RomPath (build with Callisto first)"
}

if ($SaveState -and -not $SaveStatePath) {
    $manifest = Join-Path $repoRoot "tools\test\savestates\manifest.toml"
    if (-not (Test-Path $manifest)) {
        throw "Savestate manifest not found: $manifest"
    }
    $pattern = "(?m)^\[$([regex]::Escape($SaveState))\]\s*\r?\nfile\s*=\s*`"([^`"]+)`""
    $text = Get-Content $manifest -Raw
    if ($text -notmatch $pattern) {
        throw "Unknown savestate '$SaveState' in manifest.toml"
    }
    $SaveStatePath = Join-Path $repoRoot $Matches[1]
}

$args = @($RomPath)
if ($Automation) {
    $lua = Join-Path $PSScriptRoot "automation.lua"
    if (-not (Test-Path $lua)) { throw "Missing automation.lua" }
    $env:MESEN_AUTOMATION_DIR = Join-Path $PSScriptRoot ".automation"
    $args += (Resolve-Path $lua).Path
} elseif ($SaveStatePath) {
    if (-not (Test-Path $SaveStatePath)) {
        throw "Savestate file not found: $SaveStatePath"
    }
    $args += (Resolve-Path $SaveStatePath).Path
}

Write-Host "Launching Mesen: $mesenExe"
Write-Host "  ROM: $($args[0])"
if ($args.Count -gt 1) {
    Write-Host "  Savestate: $($args[1])"
}

Start-Process -FilePath $mesenExe -ArgumentList $args
if ($Automation) {
    Write-Host "Automation bridge active. Run: tools/test/mesen/run-session.ps1 -Slot 1 -WalkRight"
} else {
    Write-Host "Then in a Cursor terminal:"
    Write-Host "  1. tools/test/mesen/start-mcp.ps1"
    Write-Host "  2. In Mesen: Tools -> MCP Server -> Start"
}
