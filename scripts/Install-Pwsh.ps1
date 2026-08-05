#Requires -Version 5.1
<#
.SYNOPSIS
  Install PowerShell 7 (pwsh) if missing, ensure User PATH, print path for WezTerm.

.DESCRIPTION
  Order:
    1) Already installed? -> verify + PATH, exit 0
    2) winget install Microsoft.PowerShell
    3) Fallback: latest win-x64 MSI from GitHub (needs admin UAC)

  Idempotent. Safe to re-run.

.EXAMPLE
  .\scripts\Install-Pwsh.ps1
  .\scripts\Install-Pwsh.ps1 -SkipMsiFallback
#>
[CmdletBinding()]
param(
  # Do not download/run MSI if winget fails (CI / offline policy).
  [switch]$SkipMsiFallback
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"

function Get-PwshVersionString {
  param([string]$Exe)
  try {
    $v = & $Exe -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
    if ($LASTEXITCODE -eq 0 -and $v) { return ($v | Out-String).Trim() }
  }
  catch { }
  return $null
}

function Install-PwshViaMsi {
  Write-Info 'Downloading latest PowerShell win-x64 MSI from GitHub...'
  $apiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
  try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'wezterm-setup' } -TimeoutSec 60
  }
  catch {
    throw "GitHub API failed: $($_.Exception.Message)"
  }

  $asset = $release.assets |
    Where-Object { $_.name -match 'PowerShell-.*-win-x64\.msi$' } |
    Select-Object -First 1

  if (-not $asset) {
    throw 'No win-x64 MSI asset found on latest PowerShell release.'
  }

  $tmp = Join-Path $env:TEMP $asset.name
  Write-Info "GET $($asset.browser_download_url)"
  Write-Info " -> $tmp"
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmp -UseBasicParsing -TimeoutSec 600

  if (-not (Test-Path -LiteralPath $tmp)) {
    throw "Download failed: $tmp"
  }

  # Quiet machine install; ADD_PATH so installer touches PATH.
  $msiArgs = @(
    '/i', "`"$tmp`"",
    '/qn',
    'ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1',
    'ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=0',
    'ENABLE_PSREMOTING=0',
    'REGISTER_MANIFEST=1',
    'USE_MU=1',
    'ENABLE_MU=1',
    'ADD_PATH=1'
  )

  Write-Info 'Running MSI (UAC elevation may prompt)...'
  if (Test-IsAdministrator) {
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
  }
  else {
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru -Verb RunAs
  }

  if ($null -eq $p) {
    throw 'msiexec did not start (UAC cancelled?).'
  }
  if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
    # 3010 = success, reboot recommended
    throw "msiexec exit code $($p.ExitCode)"
  }

  Write-Ok "MSI finished (exit $($p.ExitCode))"
}

Write-Step 'PowerShell 7 (pwsh)'

$existing = Resolve-PwshPath
if ($existing) {
  $ver = Get-PwshVersionString -Exe $existing
  Write-Ok "already installed: $existing$(if ($ver) { "  ($ver)" })"
}
else {
  Write-Info 'pwsh not found - installing...'

  $wingetResult = Invoke-WingetInstall -PackageId 'Microsoft.PowerShell' -DisplayName 'PowerShell 7'
  if (-not $wingetResult.Ok) {
    Write-Warn $wingetResult.Reason
    if ($SkipMsiFallback) {
      Write-Fail 'winget failed and -SkipMsiFallback set.'
      exit 1
    }
    try {
      Install-PwshViaMsi
    }
    catch {
      Write-Fail $_.Exception.Message
      Write-Host ''
      Write-Host 'Manual fix:' -ForegroundColor Yellow
      Write-Host '  winget install --id Microsoft.PowerShell -e' -ForegroundColor Yellow
      Write-Host '  or https://aka.ms/powershell-release?tag=stable' -ForegroundColor Yellow
      exit 1
    }
  }
  else {
    if ($wingetResult.AlreadyPresent) {
      Write-Ok 'winget reports PowerShell already present / up to date'
    }
    else {
      Write-Ok 'winget installed Microsoft.PowerShell'
    }
  }

  # PATH may have been updated by installer; refresh process PATH from Machine+User.
  $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = @($machinePath, $userPath) -join ';'

  $existing = Resolve-PwshPath
  if (-not $existing) {
    # Brief wait - installers sometimes finish writing after process exit
    Start-Sleep -Seconds 2
    $existing = Resolve-PwshPath
  }

  if (-not $existing) {
    Write-Fail 'Install finished but pwsh.exe still not found.'
    Write-Info "Looked for: $((Get-PwshCandidates) -join '; ')"
    exit 1
  }

  $ver = Get-PwshVersionString -Exe $existing
  Write-Ok "installed: $existing$(if ($ver) { "  ($ver)" })"
}

# Ensure the directory of the real binary is on User PATH (shims / new shells).
$binDir = Split-Path -Parent $existing
if (Update-UserPathEntry -Dir $binDir) {
  Write-Ok "added to User PATH: $binDir"
}
else {
  Write-Info "User PATH already has: $binDir"
}

$preferred = Get-PreferredPwshPath
if ($existing -ne $preferred -and -not (Test-Path -LiteralPath $preferred)) {
  Write-Warn "pwsh is not at the usual path:"
  Write-Warn "  actual:    $existing"
  Write-Warn "  preferred: $preferred"
  Write-Warn 'wezterm.lua resolves common paths automatically; no edit needed if Verify passes.'
}

Write-Host ''
Write-Host "PWSH_PATH=$existing" -ForegroundColor Magenta
exit 0
