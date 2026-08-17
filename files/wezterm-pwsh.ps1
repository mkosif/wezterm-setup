# WezTerm / pwsh init. Loaded by WezTerm default_prog (Documents $PROFILE is CFA-blocked).
# Safe to dot-source twice.
if ($global:KosifWezInit) { return }
$global:KosifWezInit = $true

chcp 65001 | Out-Null
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)

$script:WezKeysPath = Join-Path $env:USERPROFILE "config\wezterm-keys.md"

function global:keys {
    $path = $script:WezKeysPath
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "Cheatsheet missing: $path" -ForegroundColor Red
        return
    }
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        bat --paging=never --style=plain --language=markdown $path
    }
    else {
        Get-Content -LiteralPath $path -Raw | Write-Host
    }
}
Set-Alias -Name helpme -Value keys -Scope Global -Force

function global:boot {
    $bootPath = Join-Path $env:USERPROFILE "config\ai\BOOTSTRAP.md"
    if (-not (Test-Path -LiteralPath $bootPath)) {
        Write-Host "Missing: $bootPath" -ForegroundColor Red
        return
    }
    Get-Content -LiteralPath $bootPath -Raw | Set-Clipboard
    Write-Output "BOOTSTRAP copied to clipboard"
}

# OLED: directory names as bright FG, never a light background.
if ($null -ne $PSStyle -and $null -ne $PSStyle.FileInfo) {
    $PSStyle.FileInfo.Directory = "`e[38;2;121;192;255;1m"
    $PSStyle.FileInfo.SymbolicLink = "`e[38;2;86;212;221;1m"
    $PSStyle.FileInfo.Executable = "`e[38;2;86;240;160;1m"
    $PSStyle.FileInfo.Extension['.md'] = "`e[38;2;210;168;255m"
    $PSStyle.FileInfo.Extension['.json'] = "`e[38;2;240;214;106m"
    $PSStyle.FileInfo.Extension['.ps1'] = "`e[38;2;86;240;160m"
    $PSStyle.FileInfo.Extension['.py'] = "`e[38;2;86;240;160m"
    $PSStyle.FileInfo.Extension['.ts'] = "`e[38;2;121;192;255m"
    $PSStyle.FileInfo.Extension['.js'] = "`e[38;2;240;214;106m"
}

# OSC 7 so WezTerm knows the real cwd (new tab / Explorer / status).
function global:prompt {
    $loc = $executionContext.SessionState.Path.CurrentLocation
    $osc7 = ""
    if ($loc.Provider.Name -eq "FileSystem") {
        $esc = [char]27
        $provider_path = $loc.ProviderPath -replace "\\", "/"
        $osc7 = "${esc}]7;file://${env:COMPUTERNAME}/${provider_path}${esc}\"
    }
    $short = [string]$loc.Path
    if ($env:USERPROFILE -and $short.StartsWith($env:USERPROFILE, [StringComparison]::OrdinalIgnoreCase)) {
        $short = "~" + $short.Substring($env:USERPROFILE.Length)
    }
    "${osc7}$short$('>' * ($nestedPromptLevel + 1)) "
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { zoxide init powershell | Out-String })
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function global:ls { eza --group-directories-first --icons=auto @args }
    function global:ll { eza -la --group-directories-first --icons=auto @args }
    function global:lt { eza -laT --group-directories-first --icons=auto -L 2 @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    function global:cat { bat --paging=never --style=plain @args }
    function global:batp { bat @args }
}

function global:.. { Set-Location .. }
function global:... { Set-Location ..\.. }
function global:ww { Set-Location (Join-Path $env:USERPROFILE "work") }
function global:home { Set-Location $env:USERPROFILE }
function global:o {
    if ($args.Count -gt 0) { explorer.exe @args } else { explorer.exe . }
}
function global:cpath {
    Set-Clipboard -Value (Get-Location).Path
    Write-Host "copied: $((Get-Location).Path)"
}

if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit -Scope Global -Force
}

# Same process — WezTerm is already Grok-capable. No second GUI.
function global:grok {
    $grokExe = Join-Path $env:USERPROFILE ".grok\bin\grok.exe"
    if (-not (Test-Path -LiteralPath $grokExe)) {
        $found = Get-Command grok.exe -ErrorAction SilentlyContinue
        if ($found) { $grokExe = $found.Source }
    }
    if (-not $grokExe -or -not (Test-Path -LiteralPath $grokExe)) {
        Write-Error "grok.exe not found"
        return
    }
    & $grokExe @args
}
Set-Alias -Name gg -Value grok -Scope Global -Force
if (Get-Command rg -ErrorAction SilentlyContinue) {
    function global:ff { rg -n --hidden --glob "!.git" @args }
}
if (Get-Command fd -ErrorAction SilentlyContinue) {
    function global:fdf { fd --hidden --exclude .git @args }
}

if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    try {
        Set-PSReadLineOption -PredictionSource History
        # ListView steals half the viewport. Inline stays out of the way.
        Set-PSReadLineOption -PredictionViewStyle InlineView
    }
    catch {
        # older PSReadLine
    }
}
