#Requires -Version 5.1
<#
.SYNOPSIS
  New-machine bootstrap for this WezTerm setup.

  Installs (if missing): PowerShell 7, WezTerm, JetBrainsMono Nerd Font Mono
  Copies config via import.ps1
  Verifies with scripts\Verify-Setup.ps1

  Runs on Windows PowerShell 5.1 (stock Win11) or PowerShell 7.
  Idempotent - safe to re-run.

.EXAMPLE
  cd $HOME\work\wezterm-setup
  .\setup.ps1

  .\setup.ps1 -SkipWezTerm          # only pwsh + fonts + config
  .\setup.ps1 -SkipPwsh -SkipFonts  # config only (import)
#>
[CmdletBinding()]
param(
  [switch]$SkipPwsh,
  [switch]$SkipWezTerm,
  [switch]$SkipFonts,
  [switch]$SkipImport,
  [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
Set-Location -LiteralPath $RepoRoot

. "$RepoRoot\scripts\lib.ps1"

function Invoke-ScriptChecked {
  param(
    [Parameter(Mandatory)][string]$Path,
    [string]$Label
  )
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing script: $Path"
  }
  Write-Host ""
  Write-Host "-------- $Label --------" -ForegroundColor Cyan
  # Call as separate process so exit codes are clean and PS 5.1/7 both behave.
  $psExe = Join-Path $PSHOME 'powershell.exe'
  if (Test-Path -LiteralPath (Join-Path $PSHOME 'pwsh.exe')) {
    $psExe = Join-Path $PSHOME 'pwsh.exe'
  }
  # Prefer the host that is running us (handles 5.1 vs 7).
  if ($PSVersionTable.PSVersion.Major -ge 6) {
    $pwshCmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshCmd -and $pwshCmd.Source) {
      $hostExe = $pwshCmd.Source
    }
    else {
      $hostExe = $psExe
    }
  }
  else {
    $psCmd = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($psCmd -and $psCmd.Source) {
      $hostExe = $psCmd.Source
    }
    else {
      $hostExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    }
  }

  $args = @(
    '-NoLogo',
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', $Path
  )
  $p = Start-Process -FilePath $hostExe -ArgumentList $args -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0) {
    throw "$Label failed (exit $($p.ExitCode)): $Path"
  }
}

Write-Host ''
Write-Host 'wezterm-setup  bootstrap' -ForegroundColor Cyan
Write-Host "repo    $RepoRoot"
Write-Host "host    PS $($PSVersionTable.PSVersion) | $([Environment]::OSVersion.VersionString)"
Write-Host "admin   $(Test-IsAdministrator)"
Write-Host ''

# 0) folders WezTerm / shell expect
Write-Step 'Home folders'
Ensure-HomeDirs -Relative @('work', 'config', 'tools', 'tmp')

# 1) PowerShell 7
if (-not $SkipPwsh) {
  Invoke-ScriptChecked -Path (Join-Path $RepoRoot 'scripts\Install-Pwsh.ps1') -Label 'Install-Pwsh'
}
else {
  Write-Warn 'skipped Install-Pwsh (-SkipPwsh)'
}

# 2) WezTerm app
if (-not $SkipWezTerm) {
  Invoke-ScriptChecked -Path (Join-Path $RepoRoot 'scripts\Install-WezTerm.ps1') -Label 'Install-WezTerm'
}
else {
  Write-Warn 'skipped Install-WezTerm (-SkipWezTerm)'
}

# 3) Fonts
if (-not $SkipFonts) {
  Invoke-ScriptChecked -Path (Join-Path $RepoRoot 'scripts\Install-Fonts.ps1') -Label 'Install-Fonts'
}
else {
  Write-Warn 'skipped Install-Fonts (-SkipFonts)'
}

# 4) Config files -> live paths
if (-not $SkipImport) {
  Write-Host ''
  Write-Host '-------- import config --------' -ForegroundColor Cyan
  $import = Join-Path $RepoRoot 'import.ps1'
  # import already installs fonts; pass -SkipFonts so we do not double-copy after Install-Fonts
  & $import -SkipFonts
  if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw "import.ps1 failed (exit $LASTEXITCODE)"
  }
}
else {
  Write-Warn 'skipped import.ps1 (-SkipImport)'
}

# 5) Verify
if (-not $SkipVerify) {
  Invoke-ScriptChecked -Path (Join-Path $RepoRoot 'scripts\Verify-Setup.ps1') -Label 'Verify-Setup'
}
else {
  Write-Warn 'skipped Verify-Setup (-SkipVerify)'
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host ' bootstrap finished' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host ''
Write-Host '1. Fully quit WezTerm (check system tray).' -ForegroundColor White
Write-Host '2. Start WezTerm again.' -ForegroundColor White
Write-Host '3. Confirm:  $PSVersionTable.PSVersion   ->  7.x' -ForegroundColor White
Write-Host '4. Confirm:  icons in `ls` / cheatsheet look correct (Nerd Font).' -ForegroundColor White
Write-Host '5. Type:  keys   for the shortcut guide.' -ForegroundColor White
Write-Host ''
Write-Host 'Docs: docs\NEW-MACHINE.md' -ForegroundColor DarkGray
exit 0
