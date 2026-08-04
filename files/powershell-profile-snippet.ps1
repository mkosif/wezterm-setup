# Ensure UTF-8 for consistent glyphs/Turkish characters
chcp 65001 | Out-Null
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)

# Temporarily disabled: dotfiles will be restored under a more appropriate location.
# . "$HOME\doc\priv\kosif\dotfiles\windows\powershell\Microsoft.PowerShell_profile.ps1"

# OLED / pure-black terminals: never paint directory names with a light background.
# Default PSStyle uses blue BACKGROUND; with bright theme blues that becomes
# turquoise-on-white mush. Use bright foreground only.
if ($null -ne $PSStyle -and $null -ne $PSStyle.FileInfo) {
    $PSStyle.FileInfo.Directory    = "`e[38;2;121;192;255;1m"  # bright blue FG, bold
    $PSStyle.FileInfo.SymbolicLink = "`e[38;2;86;212;221;1m"   # cyan FG
    $PSStyle.FileInfo.Executable   = "`e[38;2;86;240;160;1m"   # green FG
    $PSStyle.FileInfo.Extension['.md']   = "`e[38;2;210;168;255m"
    $PSStyle.FileInfo.Extension['.json'] = "`e[38;2;240;214;106m"
    $PSStyle.FileInfo.Extension['.ps1']  = "`e[38;2;86;240;160m"
    $PSStyle.FileInfo.Extension['.py']   = "`e[38;2;86;240;160m"
    $PSStyle.FileInfo.Extension['.ts']   = "`e[38;2;121;192;255m"
    $PSStyle.FileInfo.Extension['.js']   = "`e[38;2;240;214;106m"
}

function boot {
    Get-Content "$HOME\config\ai\BOOTSTRAP.md" | Set-Clipboard
    Write-Output "BOOTSTRAP copied to clipboard"
}
