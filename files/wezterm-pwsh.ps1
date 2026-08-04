# Loaded by WezTerm on shell start (Documents profile is CFA-protected).
# Keep this light: no starship (git status overhead).
# Type `keys` anytime for the full cheatsheet.

$script:WezKeysPath = Join-Path $env:USERPROFILE "config\wezterm-keys.md"

# --- Cheatsheet: keys / helpme ---
function global:keys {
    $path = $script:WezKeysPath
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "Cheatsheet missing: $path" -ForegroundColor Red
        return
    }
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        bat --paging=never --style=plain --language=markdown $path
    } else {
        Get-Content -LiteralPath $path -Raw | Write-Host
    }
}
Set-Alias -Name helpme -Value keys -Scope Global -Force

# Quiet one-liner so you remember it exists
Write-Host "  keys  " -NoNewline -ForegroundColor Black -BackgroundColor DarkCyan
Write-Host " shortcut cheatsheet" -ForegroundColor DarkGray

# --- OLED FileInfo colors (no light directory backgrounds) ---
if ($null -ne $PSStyle -and $null -ne $PSStyle.FileInfo) {
    $PSStyle.FileInfo.Directory    = "`e[38;2;121;192;255;1m"
    $PSStyle.FileInfo.SymbolicLink = "`e[38;2;86;212;221;1m"
    $PSStyle.FileInfo.Executable   = "`e[38;2;86;240;160;1m"
    $PSStyle.FileInfo.Extension['.md']   = "`e[38;2;210;168;255m"
    $PSStyle.FileInfo.Extension['.json'] = "`e[38;2;240;214;106m"
    $PSStyle.FileInfo.Extension['.ps1']  = "`e[38;2;86;240;160m"
    $PSStyle.FileInfo.Extension['.py']   = "`e[38;2;86;240;160m"
    $PSStyle.FileInfo.Extension['.ts']   = "`e[38;2;121;192;255m"
    $PSStyle.FileInfo.Extension['.js']   = "`e[38;2;240;214;106m"
}

# --- Tell WezTerm the real cwd (OSC 7) ---
function global:prompt {
    $loc = $executionContext.SessionState.Path.CurrentLocation
    $osc7 = ""
    if ($loc.Provider.Name -eq "FileSystem") {
        $esc = [char]27
        $provider_path = $loc.ProviderPath -Replace "\\", "/"
        $osc7 = "${esc}]7;file://${env:COMPUTERNAME}/${provider_path}${esc}\"
    }
    "${osc7}PS $loc$('>' * ($nestedPromptLevel + 1)) "
}

# --- zoxide: fast jump (no git, no starship) ---
#   z whisper   z work   zi (interactive if fzf present)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { zoxide init powershell | Out-String })
}

# --- eza: better ls (icons need Nerd Font — you have it) ---
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function global:ls { eza --group-directories-first --icons=auto @args }
    # no --git here (keeps ll fast; use `lg` / lazygit when you want git UI)
    function global:ll { eza -la --group-directories-first --icons=auto @args }
    function global:lt { eza -laT --group-directories-first --icons=auto -L 2 @args }
}

# --- bat: nicer file view (git/delta stay separate) ---
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function global:cat { bat --paging=never --style=plain @args }
    function global:batp { bat @args }
}

# --- navigation / open helpers ---
function global:.. { Set-Location .. }
function global:... { Set-Location ..\.. }
function global:ww { Set-Location (Join-Path $env:USERPROFILE 'work') }
function global:home { Set-Location $env:USERPROFILE }
function global:o {
    # open cwd (or path) in Explorer
    if ($args.Count -gt 0) { explorer.exe @args } else { explorer.exe . }
}
function global:cpath {
    # copy cwd to clipboard
    Set-Clipboard -Value (Get-Location).Path
    Write-Host "copied: $((Get-Location).Path)"
}

# --- git / tools shortcuts (only if installed) ---
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit -Scope Global -Force
}
if (Get-Command rg -ErrorAction SilentlyContinue) {
    # keep name rg; add a short search helper
    function global:ff { rg -n --hidden --glob '!.git' @args }
}
if (Get-Command fd -ErrorAction SilentlyContinue) {
    function global:fdf { fd --hidden --exclude .git @args }
}

# --- PSReadLine: history menu + prediction (fast, no git) ---
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
        # older PSReadLine — ignore
    }
}
