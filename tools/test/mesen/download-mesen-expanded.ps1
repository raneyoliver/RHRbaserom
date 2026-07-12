# Downloads Mesen2-Expanded (Hoshiruna fork with MCP debugger) for Windows AoT.
# Run from repo root: powershell -File tools/test/mesen/download-mesen-expanded.ps1

$ErrorActionPreference = "Stop"
$dest = Join-Path (Join-Path $PSScriptRoot "..\..") "mesen2-expanded"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$zip = Join-Path $env:TEMP "mesen-expanded-win-aot.zip"
$url = "https://nightly.link/Hoshiruna/Mesen2-Expanded/workflows/build.yml/master/Mesen%20(Windows%20-%20net8.0%20-%20AoT).zip"

Write-Host "Downloading Mesen2-Expanded..."
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

if ((Get-Item $zip).Length -lt 1MB) {
    throw "Download failed or artifact unavailable. Try manually from https://github.com/Hoshiruna/Mesen2-Expanded/actions"
}

Expand-Archive -Path $zip -DestinationPath $dest -Force
Remove-Item $zip -Force

$exe = Join-Path $dest "Mesen.exe"
if (-not (Test-Path $exe)) {
    throw "Mesen.exe not found after extract"
}

Write-Host "Installed: $exe"

# CI artifacts ship Mesen.exe only; build MCPServer.exe locally for MCP HTTP bridge.
$cpp = Join-Path $dest "MCPServer.cpp"
$mcp = Join-Path $dest "MCPServer.exe"
if (-not (Test-Path $mcp)) {
    Write-Host "Building MCPServer.exe..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Hoshiruna/Mesen2-Expanded/master/MCPServer/MCPServer.cpp" -OutFile $cpp -UseBasicParsing
    $vcvars = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    if (-not (Test-Path $vcvars)) {
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        $install = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        $vcvars = Join-Path $install "VC\Auxiliary\Build\vcvars64.bat"
    }
    if (-not (Test-Path $vcvars)) {
        throw "MCPServer.exe missing and MSVC not found. Install VS Build Tools with C++ workload."
    }
    cmd /c "`"$vcvars`" && cd /d `"$dest`" && cl /nologo /EHsc /O2 /std:c++20 MCPServer.cpp /Fe:MCPServer.exe ws2_32.lib"
    if (-not (Test-Path $mcp)) { throw "MCPServer.exe build failed" }
    Remove-Item (Join-Path $dest "MCPServer.obj") -ErrorAction SilentlyContinue
    Write-Host "Built: $mcp"
}
