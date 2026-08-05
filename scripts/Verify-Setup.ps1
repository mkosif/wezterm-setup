#Requires -Version 5.1
<#
.SYNOPSIS
  Verify pwsh, fonts, WezTerm config paths, and optional wezterm font listing.

.EXAMPLE
  .\scripts\Verify-Setup.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"

$failed = 0
$ExpectedFamily = 'JetBrainsMono Nerd Font Mono'

Write-Step 'Verify wezterm-setup'

# --- dirs ---
foreach ($d in @('work', 'config')) {
  $p = Join-Path $env:USERPROFILE $d
  if (Test-Path -LiteralPath $p) { Write-Ok "~\$d" }
  else { Write-Fail "~\$d missing"; $failed++ }
}

# --- pwsh ---
$pwsh = Resolve-PwshPath
if ($pwsh) {
  Write-Ok "pwsh  $pwsh"
  try {
    $ver = & $pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
    if ($ver) { Write-Info "version $(($ver | Out-String).Trim())" }
  }
  catch { }
}
else {
  Write-Fail 'pwsh.exe not found - run scripts\Install-Pwsh.ps1'
  $failed++
}

# --- live config files ---
$checks = @(
  @{ Path = (Join-Path $env:USERPROFILE '.wezterm.lua'); Name = '~/.wezterm.lua' }
  @{ Path = (Join-Path $env:USERPROFILE 'config\wezterm-pwsh.ps1'); Name = '~/config/wezterm-pwsh.ps1' }
  @{ Path = (Join-Path $env:USERPROFILE 'config\wezterm-keys.md'); Name = '~/config/wezterm-keys.md' }
)
foreach ($c in $checks) {
  if (Test-Path -LiteralPath $c.Path) { Write-Ok $c.Name }
  else {
    Write-Fail ($c.Name + ' missing - run .\import.ps1 or .\setup.ps1')
    $failed++
  }
}

# --- wezterm.lua mentions expected font family ---
$lua = Join-Path $env:USERPROFILE '.wezterm.lua'
if (Test-Path -LiteralPath $lua) {
  $text = Get-Content -LiteralPath $lua -Raw -ErrorAction SilentlyContinue
  if ($text -match [regex]::Escape($ExpectedFamily)) {
    Write-Ok "config selects font family: $ExpectedFamily"
  }
  else {
    Write-Warn "config may not reference '$ExpectedFamily' (check font fallbacks)"
  }
  if ($text -match 'PowerShell\\7\\pwsh|resolve_pwsh|pwsh\.exe') {
    Write-Ok 'config references pwsh as default shell'
  }
  else {
    Write-Warn 'config may not set pwsh as default_prog'
  }
}

# --- fonts on disk ---
$userFontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$sysFontDir = Join-Path $env:WINDIR 'Fonts'
$fontHits = @()
if (Test-Path -LiteralPath $userFontDir) {
  $fontHits += Get-ChildItem -LiteralPath $userFontDir -Filter 'JetBrainsMonoNerdFontMono-*.ttf' -File -EA SilentlyContinue
}
if (Test-Path -LiteralPath $sysFontDir) {
  $fontHits += Get-ChildItem -LiteralPath $sysFontDir -Filter 'JetBrainsMonoNerdFontMono-*.ttf' -File -EA SilentlyContinue
}
$fontHits = @($fontHits | Sort-Object Name -Unique)
if ($fontHits.Count -gt 0) {
  $n = $fontHits.Count
  Write-Ok "font files present ($n x JetBrainsMonoNerdFontMono-*.ttf)"
}
else {
  Write-Fail 'JetBrainsMono Nerd Font Mono TTF not found - run scripts\Install-Fonts.ps1'
  $failed++
}

# --- wezterm binary ---
$wez = Get-Command wezterm -ErrorAction SilentlyContinue
if ($wez) {
  Write-Ok "wezterm  $($wez.Source)"
  try {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $list = & wezterm ls-fonts --list-system 2>&1 | Out-String
    $ErrorActionPreference = $prev
    if ($list -match [regex]::Escape($ExpectedFamily)) {
      Write-Ok "wezterm lists: $ExpectedFamily"
    }
    else {
      Write-Warn "wezterm does not list '$ExpectedFamily' yet - fully restart WezTerm"
    }
  }
  catch {
    Write-Warn "ls-fonts: $($_.Exception.Message)"
  }
}
else {
  Write-Warn 'wezterm not on PATH - install WezTerm (setup.ps1 or scripts\Install-WezTerm.ps1)'
}

Write-Host ''
if ($failed -gt 0) {
  Write-Fail ("verify failed (" + $failed + " issue(s))")
  exit 1
}

Write-Ok 'all critical checks passed'
Write-Host ''
Write-Host 'Next: fully quit WezTerm and reopen. New tabs should be PowerShell 7 + Nerd Font.' -ForegroundColor DarkGray
exit 0
