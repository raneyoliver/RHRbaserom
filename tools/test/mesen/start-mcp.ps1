# Run MCPServer in this Cursor terminal (for live logs).
#
# Usage:
#   1. Run: .\tools\test\mesen\start-mcp.ps1
#   2. In Mesen: Tools -> MCP Server -> Start
#
# If MCP is already running in a separate window, click Stop in Mesen first.
# Use reset-mcp.ps1 only when things are stuck (port open but pipe down).

param(
    # 52000: Windows Hyper-V/WSL often excludes 51136-51235, so 51234 fails
    # with "already in use" even when netstat shows nothing.
    [int]$Port = 52000
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$mesenDir = Join-Path $repoRoot "tools\mesen2-expanded"
$mcpExe = Join-Path $mesenDir "MCPServer.exe"

if (-not (Test-Path $mcpExe)) {
    throw "MCPServer.exe not found. Run: tools/test/mesen/download-mesen-expanded.ps1"
}

$mesen = Get-Process -Name "Mesen" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $mesen) {
    throw "Mesen is not running. Run: tools/test/mesen/launch.ps1"
}

function Test-MesenDebugPipe {
    try {
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(
            ".", "MesenDebug",
            [System.IO.Pipes.PipeDirection]::InOut,
            [System.IO.Pipes.PipeOptions]::None)
        $pipe.Connect(2000)
        $pipe.Close()
        return $true
    } catch {
        return $false
    }
}

function Test-McpPort([int]$p) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect("127.0.0.1", $p, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(500)
        if ($ok -and $client.Connected) {
            $client.Close()
            return $true
        }
        $client.Close()
    } catch {}
    return $false
}

$pipeUp = Test-MesenDebugPipe
$portUp = Test-McpPort $Port

# Windows Hyper-V/WSL reserves blocks of ports; bind fails with "already in use"
# even when netstat is empty. 51234 sits in a common exclusion (51136-51235).
try {
    $excl = netsh interface ipv4 show excludedportrange protocol=tcp
    if ($excl -match '\b51136\b' -or ($excl | Select-String -Pattern "\s+$Port\s+" -Quiet)) {
        foreach ($line in ($excl -split "`n")) {
            if ($line -match '^\s*(\d+)\s+(\d+)') {
                $start = [int]$Matches[1]; $end = [int]$Matches[2]
                if ($Port -ge $start -and $Port -le $end) {
                    Write-Host "WARNING: port $Port is in a Windows excluded range ($start-$end)."
                    Write-Host "Use 52000 (script default) or run patch-mesen-mcp-port.ps1 / free the range as admin."
                }
            }
        }
    }
} catch {}

if ($portUp -and (-not $pipeUp)) {
    throw "Port $Port is in use but Mesen's debugger pipe is down (stale bridge). Run: .\tools\test\mesen\reset-mcp.ps1 then run this script and Start MCP in Mesen."
}

if ($portUp -and $pipeUp) {
    Write-Host "MCP is already running (Mesen started it in a separate window)."
    Write-Host ""
    Write-Host "To show logs in this terminal instead:"
    Write-Host "  1. Mesen -> Tools -> MCP Server -> Stop"
    Write-Host "  2. Run this script again"
    Write-Host "  3. Mesen -> Tools -> MCP Server -> Start"
    exit 1
}

Write-Host "Starting MCPServer in this terminal on http://127.0.0.1:$Port/mcp"
if (-not $pipeUp) {
    Write-Host "Waiting for debugger pipe... In Mesen, click: Tools -> MCP Server -> Start"
} else {
    Write-Host "Debugger pipe is up. Attaching HTTP bridge."
}
Write-Host "Press Ctrl+C to stop."
Write-Host ""

Set-Location $mesenDir
& $mcpExe $Port
