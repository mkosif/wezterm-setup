#Requires -Version 5.1
<#
.SYNOPSIS
  Install repo WezTerm config (+ Mono Nerd Font) onto this machine.
  Existing targets are backed up as *.bak-yyyyMMdd-HHmmss before overwrite.

.EXAMPLE
  cd ~/work/wezterm-setup
  .\import.ps1
  .\import.ps1 -SkipFonts
  .\import.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [switch]$SkipFonts
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
$MapPath = Join-Path $RepoRoot 'files.map.psd1'
if (-not (Test-Path -LiteralPath $MapPath)) {
  throw "Missing map: $MapPath"
}

$Map = Import-PowerShellDataFile -Path $MapPath
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ok = 0
$missing = 0
$backed = 0

function Expand-TargetPath([string]$Template) {
  $thr = $ExecutionContext.InvokeCommand.ExpandString($Template)
  return [Environment]::ExpandEnvironmentVariables($thr)
}

function Backup-IfExists([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $false }
  $bak = "$Path.bak-$stamp"
  Copy-Item -LiteralPath $Path -Destination $bak -Force
  Write-Host "  BAK   $bak" -ForegroundColor DarkYellow
  return $true
}

function Install-UserFont([string]$TtfPath) {
  $name = [IO.Path]::GetFileName($TtfPath)
  $destDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  if (-not (Test-Path -LiteralPath $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }
  $dest = Join-Path $destDir $name
  Copy-Item -LiteralPath $TtfPath -Destination $dest -Force

  # Register for current user (no admin). Display name ≈ family for WezTerm lookup.
  $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  if (-not (Test-Path -LiteralPath $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
  }
  # Value name Windows shows; path is absolute for per-user fonts
  $valueName = "$name (TrueType)"
  New-ItemProperty -Path $regPath -Name $valueName -Value $dest -PropertyType String -Force | Out-Null
}

Write-Host "import  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "repo    $RepoRoot"
Write-Host ""

# --- config files ---
foreach ($entry in $Map.Files) {
  $srcRel = $entry.Source -replace '/', [IO.Path]::DirectorySeparatorChar
  $src = Join-Path $RepoRoot $srcRel
  $live = Expand-TargetPath $entry.Target

  if (-not (Test-Path -LiteralPath $src)) {
    Write-Host "  MISS  repo missing $($entry.Source)" -ForegroundColor Yellow
    $missing++
    continue
  }

  $liveDir = Split-Path -Parent $live
  if (-not (Test-Path -LiteralPath $liveDir)) {
    if ($PSCmdlet.ShouldProcess($liveDir, 'Create directory')) {
      New-Item -ItemType Directory -Force -Path $liveDir | Out-Null
    }
  }

  if ($PSCmdlet.ShouldProcess($live, "Install from $($entry.Source)")) {
    if (Backup-IfExists $live) { $backed++ }
    Copy-Item -LiteralPath $src -Destination $live -Force
    Write-Host "  OK    $($entry.Source)" -ForegroundColor Green
    Write-Host "     -> $live"
    $ok++
  }
}

# --- fonts ---
if (-not $SkipFonts) {
  Write-Host ""
  Write-Host "fonts" -ForegroundColor Cyan
  $repoFontDir = Join-Path $RepoRoot ($Map.Fonts.SourceDir -replace '/', [IO.Path]::DirectorySeparatorChar)
  $pattern = $Map.Fonts.Pattern

  if (-not (Test-Path -LiteralPath $repoFontDir)) {
    Write-Host "  MISS  $repoFontDir" -ForegroundColor Yellow
    $missing++
  }
  else {
    $ttfs = Get-ChildItem -LiteralPath $repoFontDir -Filter $pattern -File -ErrorAction SilentlyContinue
    if (-not $ttfs -or $ttfs.Count -eq 0) {
      Write-Host "  MISS  no $pattern under fonts/" -ForegroundColor Yellow
      $missing++
    }
    else {
      foreach ($f in $ttfs) {
        if ($PSCmdlet.ShouldProcess($f.Name, 'Install user font')) {
          Install-UserFont $f.FullName
          Write-Host "  OK    $($f.Name)" -ForegroundColor Green
          $ok++
        }
      }
    }
  }
}
else {
  Write-Host ""
  Write-Host "fonts  skipped (-SkipFonts)" -ForegroundColor DarkGray
}

# --- soft checks (warn only) ---
Write-Host ""
Write-Host "checks" -ForegroundColor Cyan
$pwsh7 = 'C:\Program Files\PowerShell\7\pwsh.exe'
if (Test-Path -LiteralPath $pwsh7) {
  Write-Host "  OK    pwsh7  $pwsh7" -ForegroundColor Green
}
else {
  Write-Host "  WARN  pwsh7 not at default path (edit wezterm.lua if needed):" -ForegroundColor Yellow
  Write-Host "        $pwsh7"
}

$work = Join-Path $HOME 'work'
if (Test-Path -LiteralPath $work) {
  Write-Host "  OK    default_cwd  $work" -ForegroundColor Green
}
else {
  Write-Host "  WARN  ~/work missing (WezTerm default_cwd). Create it or edit wezterm.lua." -ForegroundColor Yellow
}

$wez = Get-Command wezterm -ErrorAction SilentlyContinue
if ($wez) {
  Write-Host "  OK    wezterm on PATH: $($wez.Source)" -ForegroundColor Green
}
else {
  Write-Host "  WARN  wezterm not on PATH (install WezTerm separately)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "done  installed=$ok  backed_up=$backed  missing=$missing" -ForegroundColor Cyan
Write-Host "Restart WezTerm to load the new config." -ForegroundColor DarkGray
if ($missing -gt 0) { exit 1 }
