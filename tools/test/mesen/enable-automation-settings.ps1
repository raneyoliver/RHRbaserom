# Enable Mesen Lua settings required for automation.lua (file I/O + savestate load).

$ErrorActionPreference = "Stop"
$settings = Join-Path $env:USERPROFILE "Documents\Mesen2\settings.json"
if (-not (Test-Path $settings)) {
    throw "Mesen settings not found: $settings (launch Mesen once first)"
}

$text = Get-Content $settings -Raw
$updated = $false

if ($text -match '"AllowIoOsAccess":\s*false') {
    $text = $text -replace '"AllowIoOsAccess":\s*false', '"AllowIoOsAccess": true'
    $updated = $true
    Write-Host "Enabled AllowIoOsAccess (Lua file I/O for automation bridge)"
}

if ($text -match '"SaveScriptBeforeRun":\s*true') {
    $text = $text -replace '"SaveScriptBeforeRun":\s*true', '"SaveScriptBeforeRun": false'
    $updated = $true
    Write-Host "Disabled SaveScriptBeforeRun (avoid blocking auto-run)"
}

if ($text -match '"ScriptStartupBehavior":\s*"ShowTutorial"') {
    $text = $text -replace '"ScriptStartupBehavior":\s*"ShowTutorial"', '"ScriptStartupBehavior": "ShowBlankWindow"'
    $updated = $true
    Write-Host "Set ScriptStartupBehavior to ShowBlankWindow"
}

if ($updated) {
    Set-Content -Path $settings -Value $text -NoNewline -Encoding UTF8
} else {
    Write-Host "Mesen automation settings already enabled."
}
