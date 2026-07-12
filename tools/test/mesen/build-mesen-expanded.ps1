# Build patched Mesen2-Expanded (MCP automation tools) from tools/mesen2-expanded-src.
# Requires: .NET 8 SDK, Visual Studio 2022 with C++ workload.
#
# Usage:
#   .\build-mesen-expanded.ps1
#   .\build-mesen-expanded.ps1 -SkipRestore

param([switch]$SkipRestore)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$src = Join-Path $repoRoot "tools\mesen2-expanded-src"
$dest = Join-Path $repoRoot "tools\mesen2-expanded"
$uiProj = Join-Path $src "UI\UI.csproj"
$builtExe = Join-Path $src "build\TmpReleaseBuild\Mesen.exe"

if (-not (Test-Path $uiProj)) {
    throw "Source not found: $uiProj (clone Hoshiruna/Mesen2-Expanded to tools/mesen2-expanded-src)"
}

$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnet) { throw ".NET SDK not found. Install .NET 8 SDK." }

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "vswhere not found. Install Visual Studio 2022." }
$installs = @(& $vswhere -all -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
$install = $installs | Where-Object { $_ -match "Community" } | Select-Object -First 1
if (-not $install) { $install = $installs | Select-Object -First 1 }
$msbuild = Join-Path $install "MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path $msbuild)) { throw "MSBuild not found under: $install" }

Push-Location $src
try {
    if (-not $SkipRestore) {
        Write-Host "Restoring NuGet packages..."
        & dotnet restore -p:TargetFramework=net8.0 -r win-x64 -p:PublishAot=true -p:BuildWithNetFrameworkHostedCompiler=true
    }

    Write-Host "Building native core (Release x64)..."
    & $msbuild -nologo -m -p:Configuration=Release -p:Platform=x64 -t:InteropDLL Mesen.sln
    if ($LASTEXITCODE -ne 0) { throw "Native MSBuild failed with exit code $LASTEXITCODE" }

    $solutionDir = $src
    $outDir = Join-Path $src 'bin\win-x64\Release'
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $nuget = Join-Path $env:USERPROFILE '.nuget\packages'
    foreach ($pair in @(
            @{ pkg = 'harfbuzzsharp'; dll = 'libHarfBuzzSharp.dll' },
            @{ pkg = 'skiasharp'; dll = 'libSkiaSharp.dll' }
        )) {
        $native = Get-ChildItem (Join-Path $nuget $pair.pkg) -Recurse -Filter $pair.dll -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match 'win-x64[\\/]native' } |
            Select-Object -First 1
        if ($native) {
            Copy-Item $native.FullName (Join-Path $outDir $pair.dll) -Force
        }
    }

    Write-Host "Building UI (dotnet SDK MSBuild)..."
    & dotnet build @(
        '--no-restore'
        '-c', 'Release'
        "-p:SolutionDir=$solutionDir"
        '-p:BuildProjectReferences=false'
        '-p:TargetFramework=net8.0'
        '-p:Platform=x64'
        '-r', 'win-x64'
        'UI\UI.csproj'
    )
    if ($LASTEXITCODE -ne 0) { throw "dotnet build failed with exit code $LASTEXITCODE" }

    Write-Host "Publishing AoT Mesen.exe (this may take several minutes)..."
    & dotnet publish @(
        '--no-restore'
        '-c', 'Release'
        "-p:SolutionDir=$solutionDir"
        '-p:BuildProjectReferences=false'
        '-p:PublishAot=true'
        '-p:SelfContained=true'
        '-p:PublishSingleFile=false'
        '-p:OptimizeUi=true'
        '-p:Platform=Any CPU'
        '-p:TargetFramework=net8.0'
        '-r', 'win-x64'
        'UI\UI.csproj'
        '/p:PublishProfile=Properties\PublishProfiles\Release.pubxml'
    )
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed with exit code $LASTEXITCODE" }

    if (-not (Test-Path $builtExe)) {
        throw "Expected output not found: $builtExe"
    }

    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    $backup = Join-Path $dest "Mesen.exe.bak"
    $target = Join-Path $dest "Mesen.exe"
    Get-Process -Name "Mesen" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    if (Test-Path $target) {
        Copy-Item $target $backup -Force
        Write-Host "Backed up previous Mesen.exe to Mesen.exe.bak"
    }
    Copy-Item $builtExe $target -Force
    Write-Host ""
    Write-Host "Installed patched Mesen: $target"
    Write-Host "Restart Mesen and MCP (start-mcp.ps1 + Tools -> MCP Server -> Start)."
    Write-Host "New MCP tools: load_state_slot, load_state_file, set_controller_input, run_frames"
}
finally {
    Pop-Location
}
