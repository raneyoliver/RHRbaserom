# Client for Mesen automation.lua (file-based command protocol).

function Get-AutomationDir {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
    return Join-Path $repoRoot "tools\test\mesen\.automation"
}

function Reset-AutomationIo {
    $dir = Get-AutomationDir
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Remove-Item (Join-Path $dir "cmd.txt") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $dir "result.txt") -ErrorAction SilentlyContinue
}

function Read-AutomationResult {
    $path = Join-Path (Get-AutomationDir) "result.txt"
    if (-not (Test-Path $path)) { return $null }
    $map = @{}
    Get-Content $path | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            $map[$Matches[1]] = $Matches[2]
        }
    }
    return $map
}

function Send-AutomationCommand {
    param(
        [string[]]$Lines,
        [int]$TimeoutSec = 30,
        [string[]]$WaitForStatus = @("ok", "error")
    )

    $dir = Get-AutomationDir
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $cmdPath = Join-Path $dir "cmd.txt"
    $tmpPath = Join-Path $dir "cmd.tmp"
    $resultPath = Join-Path $dir "result.txt"

    Remove-Item $resultPath -ErrorAction SilentlyContinue
    Set-Content -Path $tmpPath -Value $Lines -Encoding ASCII
    Move-Item -Path $tmpPath -Destination $cmdPath -Force

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $result = Read-AutomationResult
        if ($result -and $result.status -in $WaitForStatus) {
            return $result
        }
        Start-Sleep -Milliseconds 100
    }
    throw "Automation command timed out after ${TimeoutSec}s: $($Lines[0])"
}

function Wait-AutomationReady {
    param([int]$TimeoutSec = 60)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $result = Read-AutomationResult
        if ($result -and $result.status -eq "ready") {
            return $result
        }
        Start-Sleep -Milliseconds 200
    }
    throw "Automation bridge not ready after ${TimeoutSec}s (is automation.lua loaded?)"
}

function Invoke-MesenMcp {
    param($tool, $argsObj, $timeoutSec = 15)
    if (-not $script:McpReqId) { $script:McpReqId = 1 }
    $script:McpReqId++
    $body = @{ jsonrpc = "2.0"; id = $script:McpReqId; method = "tools/call"; params = @{ name = $tool; arguments = $argsObj } } | ConvertTo-Json -Depth 10 -Compress
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:52000/mcp" -Method POST -ContentType "application/json" -Body $body -UseBasicParsing -TimeoutSec $timeoutSec
    $parsed = $r.Content | ConvertFrom-Json
    if ($parsed.error) { throw ($parsed.error | ConvertTo-Json -Compress) }
    $text = $parsed.result.content[0].text
    if ($parsed.result.isError) { throw $text }
    return ($text | ConvertFrom-Json)
}

function Invoke-MesenMcpListTools {
    $body = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:52000/mcp" -Method POST -ContentType "application/json" -Body $body -UseBasicParsing -TimeoutSec 10
    $parsed = $r.Content | ConvertFrom-Json
    if ($parsed.error) { throw ($parsed.error | ConvertTo-Json -Compress) }
    return @($parsed.result.tools | ForEach-Object { $_.name })
}

function Read-McpU16 {
    param([int]$Address, [int]$MemoryType = 0)
    $m = Invoke-MesenMcp "get_memory_range" @{
        memory_type = $MemoryType
        start_address = $Address
        length = 2
    }
    # IMPORTANT: [byte] -shl truncates to 8 bits in PowerShell — cast to int first.
    $parts = @($m.hex -split ' ')
    if ($parts.Count -lt 2) { throw "get_memory_range returned too few bytes: $($m.hex)" }
    $lo = [Convert]::ToInt32($parts[0], 16)
    $hi = [Convert]::ToInt32($parts[1], 16)
    return ($lo + ($hi -shl 8))
}

function Read-McpHex {
    param([int]$Address, [int]$Length = 2, [int]$MemoryType = 0)
    $m = Invoke-MesenMcp "get_memory_range" @{
        memory_type = $MemoryType
        start_address = $Address
        length = $Length
    }
    return $m.hex
}

function Wait-McpPort {
    param([int]$TimeoutSec = 90, [switch]$Quiet)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $dots = 0
    while ((Get-Date) -lt $deadline) {
        if (Test-McpPort) { return $true }
        if (-not $Quiet) {
            $dots = ($dots + 1) % 4
            Write-Host ("Waiting for MCP on :52000{0}   (start-mcp.ps1 + Mesen Tools -> MCP Server -> Start)" -f ('.' * $dots)) -NoNewline
            Write-Host "`r" -NoNewline
        }
        Start-Sleep -Seconds 2
    }
    if (-not $Quiet) { Write-Host "" }
    return $false
}

function Test-McpPort {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $c.Connect("127.0.0.1", 52000)
        $ok = $c.Connected
        $c.Close()
        return $ok
    } catch { return $false }
}

function Start-MesenLuaScript {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MesenWin32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@
    $mesen = Get-Process -Name "Mesen" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $mesen) { throw "Mesen not running" }
    [MesenWin32]::SetForegroundWindow($mesen.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait("{F5}")
}
