# Claude Code dotfiles installer for Windows
# Copies Claude Code configuration files to ~\.claude\

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$SRC_DIR    = Join-Path $SCRIPT_DIR ".claude"
$DEST_DIR   = Join-Path $env:USERPROFILE ".claude"
$CMDS_DEST  = Join-Path $DEST_DIR "commands"

Write-Host "Installing Claude Code dotfiles (Windows)..."

New-Item -ItemType Directory -Force -Path $DEST_DIR  | Out-Null
New-Item -ItemType Directory -Force -Path $CMDS_DEST | Out-Null

function Install-File($src, $dest) {
    if (Test-Path $dest) {
        $backup = "$dest.backup"
        Write-Host "  Backing up $(Split-Path $dest -Leaf) -> .backup"
        Copy-Item $dest $backup -Force
    }
    Copy-Item $src $dest -Force
    Write-Host "  Installed: $dest"
}

# settings.json — generate from settings-windows.json with resolved path
$settingsSrc  = Join-Path $SCRIPT_DIR "settings-windows.json"
$settingsDest = Join-Path $DEST_DIR "settings.json"
$ps1Path = (Join-Path $DEST_DIR "statusline-command.ps1") -replace '\\', '/'
$content = (Get-Content $settingsSrc -Raw) -replace [regex]::Escape('%USERPROFILE%\\.claude'), $ps1Path.Replace('/statusline-command.ps1', '')
# Rebuild the actual command value cleanly
$content = (Get-Content $settingsSrc -Raw) -replace '%USERPROFILE%\\\\.claude', ($DEST_DIR -replace '\\', '\\\\')
$content | Set-Content $settingsDest -Encoding UTF8
Write-Host "  Installed: $settingsDest"

# statusline-command.ps1
Install-File (Join-Path $SRC_DIR "statusline-command.ps1") (Join-Path $DEST_DIR "statusline-command.ps1")

# commands/*.md
foreach ($cmd in Get-ChildItem (Join-Path $SRC_DIR "commands") -Filter "*.md") {
    Install-File $cmd.FullName (Join-Path $CMDS_DEST $cmd.Name)
}

Write-Host ""
Write-Host "Installation complete!"
Write-Host "Restart Claude Code to apply changes."
Write-Host ""
Write-Host "For session management, install cc-deck separately:"
Write-Host "  https://github.com/sysnet4admin/cc-deck"
