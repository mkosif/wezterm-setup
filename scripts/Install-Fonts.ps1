#Requires -Version 5.1
<#
.SYNOPSIS
  Install JetBrainsMono Nerd Font Mono (bundled under fonts/) for the current user.

.DESCRIPTION
  - No admin required
  - Copies TTF -> %LOCALAPPDATA%\Microsoft\Windows\Fonts
  - Registers under HKCU\...\Fonts
  - Best-effort AddFontResourceEx so apps can see fonts without logoff
  - WezTerm config already selects family: "JetBrainsMono Nerd Font Mono"

  Idempotent. Safe to re-run.

.EXAMPLE
  .\scripts\Install-Fonts.ps1
  .\scripts\Install-Fonts.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"

# Must match config.font in files/wezterm.lua
$ExpectedFamily = 'JetBrainsMono Nerd Font Mono'

Write-Step 'Fonts (JetBrainsMono Nerd Font Mono)'

$repo = Get-RepoRoot
$Map = Get-Map
$srcDir = Join-Path $repo ($Map.Fonts.SourceDir -replace '/', [IO.Path]::DirectorySeparatorChar)
$pattern = $Map.Fonts.Pattern

if (-not (Test-Path -LiteralPath $srcDir)) {
  Write-Fail "Font source dir missing: $srcDir"
  Write-Info 'Clone the full repo (fonts/ is tracked).'
  exit 1
}

$ttfs = @(Get-ChildItem -LiteralPath $srcDir -Filter $pattern -File -ErrorAction SilentlyContinue)
if ($ttfs.Count -eq 0) {
  Write-Fail "No fonts matching '$pattern' under $srcDir"
  exit 1
}

Write-Info "found $($ttfs.Count) file(s) in $srcDir"

$installed = 0
foreach ($f in $ttfs) {
  if ($PSCmdlet.ShouldProcess($f.Name, 'Install user font')) {
    $dest = Install-UserFontFile -TtfPath $f.FullName
    Write-Ok "$($f.Name)"
    Write-Info " -> $dest"
    $installed++
  }
}

Write-Host ''
Write-Ok "installed/updated $installed font file(s) for current user"
Write-Info "WezTerm family (already in wezterm.lua): $ExpectedFamily"
Write-Info 'Fallback families in config: JetBrainsMono Nerd Font, JetBrains Mono, Cascadia...'

# Optional live check if wezterm is on PATH
$wez = Get-Command wezterm -ErrorAction SilentlyContinue
if ($wez) {
  Write-Info 'Checking wezterm ls-fonts...'
  try {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $list = & wezterm ls-fonts --list-system 2>&1 | Out-String
    $ErrorActionPreference = $prev
    if ($list -match [regex]::Escape($ExpectedFamily)) {
      Write-Ok "wezterm sees family: $ExpectedFamily"
    }
    else {
      Write-Warn "wezterm did not list '$ExpectedFamily' yet."
      Write-Warn 'Fully quit WezTerm (tray too) and reopen, or sign out/in once.'
    }
  }
  catch {
    Write-Warn "wezterm ls-fonts failed: $($_.Exception.Message)"
  }
}
else {
  Write-Info 'wezterm not on PATH yet - skip ls-fonts check (install WezTerm, then re-run Verify).'
}

Write-Host ''
Write-Host "FONT_FAMILY=$ExpectedFamily" -ForegroundColor Magenta
exit 0
