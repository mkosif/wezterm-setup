# Ensure UTF-8 for consistent glyphs/Turkish characters
chcp 65001 | Out-Null
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)

# Shell aliases, prompt (OSC 7), PSReadLine, FileInfo colors.
$wezInit = Join-Path $env:USERPROFILE "config\wezterm-pwsh.ps1"
if (Test-Path -LiteralPath $wezInit) {
    . $wezInit
}
