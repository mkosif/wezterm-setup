#Requires -Version 5.1
<#
.SYNOPSIS
  Install WezTerm via winget if missing.

.EXAMPLE
  .\scripts\Install-WezTerm.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"

Write-Step 'WezTerm'

$existing = Get-Command wezterm -ErrorAction SilentlyContinue
if ($existing) {
  Write-Ok "already on PATH: $($existing.Source)"
  try {
    $v = & wezterm --version 2>&1 | Out-String
    if ($v) { Write-Info ($v.Trim()) }
  }
  catch { }
  exit 0
}

# Common install locations even if PATH not refreshed
$guesses = @(
  (Join-Path $env:ProgramFiles 'WezTerm\wezterm.exe'),
  (Join-Path $env:LOCALAPPDATA 'Programs\WezTerm\wezterm.exe'),
  (Join-Path $env:USERPROFILE 'scoop\apps\wezterm\current\wezterm.exe')
)
foreach ($g in $guesses) {
  if (Test-Path -LiteralPath $g) {
    Write-Ok "found: $g"
    $dir = Split-Path -Parent $g
    if (Update-UserPathEntry -Dir $dir) {
      Write-Ok "added to User PATH: $dir"
    }
    exit 0
  }
}

if (-not (Test-WingetAvailable)) {
  Write-Fail 'wezterm not found and winget is unavailable.'
  Write-Host 'Install from: https://wezfurlong.org/wezterm/install/windows.html' -ForegroundColor Yellow
  exit 1
}

$result = Invoke-WingetInstall -PackageId 'wez.wezterm' -DisplayName 'WezTerm'
if (-not $result.Ok) {
  Write-Fail $result.Reason
  Write-Host 'Manual: winget install --id wez.wezterm -e' -ForegroundColor Yellow
  exit 1
}

# Refresh PATH
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path = @($machinePath, $userPath) -join ';'

$existing = Get-Command wezterm -ErrorAction SilentlyContinue
if (-not $existing) {
  foreach ($g in $guesses) {
    if (Test-Path -LiteralPath $g) {
      $dir = Split-Path -Parent $g
      [void](Update-UserPathEntry -Dir $dir)
      Write-Ok "installed: $g"
      exit 0
    }
  }
  Write-Warn 'winget finished but wezterm not on PATH in this shell.'
  Write-Warn 'Open a new terminal, or re-logon, then run scripts\Verify-Setup.ps1'
  exit 0
}

Write-Ok "installed: $($existing.Source)"
exit 0
