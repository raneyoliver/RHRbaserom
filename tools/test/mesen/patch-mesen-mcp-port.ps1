# Patch Mesen.exe hardcoded MCP URL 51234 -> 52000 (same length).
# Required because Windows Hyper-V/WSL excludes 51136-51235, so bind on
# 51234 fails with "already in use" while netstat shows nothing.
#
# Close Mesen first, then run:
#   .\tools\test\mesen\patch-mesen-mcp-port.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$exe = Join-Path $repoRoot "tools\mesen2-expanded\Mesen.exe"
$py = @"
from pathlib import Path
exe = Path(r'$($exe.Replace('\','\\'))')
bak = exe.with_name('Mesen.exe.portbak')
if not exe.exists():
    raise SystemExit(f'Missing: {exe}')
data = bytearray(exe.read_bytes())
pairs = [
    (b'51234', b'52000'),
    ('51234'.encode('utf-16le'), '52000'.encode('utf-16le')),
]
total = 0
for needle, repl in pairs:
    i = 0
    while True:
        j = data.find(needle, i)
        if j < 0:
            break
        data[j:j+len(needle)] = repl
        total += 1
        i = j + len(needle)
if total == 0:
    if b'52000' in bytes(data) or '52000'.encode('utf-16le') in bytes(data):
        print('Mesen.exe already uses port 52000.')
        raise SystemExit(0)
    raise SystemExit('No 51234 strings found in Mesen.exe')
if not bak.exists():
    bak.write_bytes(exe.read_bytes())
exe.write_bytes(data)
print(f'Patched Mesen.exe MCP port 51234 -> 52000 ({total} replacements).')
print(f'Backup: {bak}')
"@

if (Get-Process -Name "Mesen" -ErrorAction SilentlyContinue) {
    throw "Close Mesen first, then re-run this script."
}

python -c $py
if ($LASTEXITCODE -ne 0) { throw "Patch failed." }
Write-Host "Next: launch Mesen, Tools -> MCP Server -> Start, then .\start-mcp.ps1"
