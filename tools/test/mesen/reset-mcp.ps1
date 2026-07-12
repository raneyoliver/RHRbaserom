# Kill orphaned MCPServer / free port 51234 when Mesen MCP gets stuck.
# Usage: .\reset-mcp.ps1

$ErrorActionPreference = "Stop"
$Port = 51234

Get-Process -Name "MCPServer" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "Stopping MCPServer PID $($_.Id)"
    Stop-Process -Id $_.Id -Force
}

$listeners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
foreach ($conn in $listeners) {
    Write-Host "Stopping listener on port $Port PID $($conn.OwningProcess)"
    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
}

Write-Host "MCP bridge reset."
Write-Host "Next:"
Write-Host "  1. Run: .\tools\test\mesen\start-mcp.ps1"
Write-Host "  2. In Mesen click Tools -> MCP Server -> Start"
