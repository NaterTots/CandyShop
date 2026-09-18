param(
    [string]$Godot = 'C:\Users\hodge\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    function Invoke-Godot([string[]]$EngineArgs) {
        & $Godot @EngineArgs
        if ($LASTEXITCODE -ne 0) { throw "Godot failed: $EngineArgs" }
    }
    Invoke-Godot -EngineArgs @('--headless', '--path', '.', '--editor', '--import')
    Invoke-Godot -EngineArgs @('--headless', '--path', '.', '--script', 'tests/test_session.gd')
    Invoke-Godot -EngineArgs @('--headless', '--path', '.', '--script', 'tests/smoke_scene.gd')
    Invoke-Godot -EngineArgs @('--headless', '--path', '.', '--script', 'tests/write_engine_notices.gd')
    New-Item -ItemType Directory -Force builds/windows, builds/linux | Out-Null
    Invoke-Godot -EngineArgs @('--headless', '--path', '.', '--export-release', 'Windows Desktop', 'builds/windows/CandyShop.exe')
    Invoke-Godot -EngineArgs @('--headless', '--path', '.', '--export-release', 'Linux', 'builds/linux/CandyShop.x86_64')
    foreach ($platform in @('windows', 'linux')) {
        Copy-Item docs/GODOT-NOTICES.txt "builds/$platform/GODOT-NOTICES.txt"
        Copy-Item docs/PLAYING.txt "builds/$platform/PLAYING.txt"
    }
    Compress-Archive -Path builds/windows/CandyShop.exe, builds/windows/GODOT-NOTICES.txt, builds/windows/PLAYING.txt -DestinationPath builds/CandyShop-Windows-x86_64.zip -Force
    # Windows tar archives require chmod +x after Unix extraction; PLAYING.txt documents it.
    tar.exe -czf builds/CandyShop-Linux-x86_64.tar.gz -C builds/linux CandyShop.x86_64 CandyShop.pck GODOT-NOTICES.txt PLAYING.txt
    if ($LASTEXITCODE -ne 0) { throw 'Linux archive creation failed' }
    Get-FileHash builds/CandyShop-Windows-x86_64.zip, builds/CandyShop-Linux-x86_64.tar.gz -Algorithm SHA256 |
        ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } |
        Set-Content builds/SHA256SUMS.txt
} finally {
    Pop-Location
}


