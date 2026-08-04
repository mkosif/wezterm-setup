#Requires -Version 5.1
<#
.SYNOPSIS
  Copy live WezTerm config (+ Mono Nerd Font) into this repo.

.EXAMPLE
  cd ~/work/wezterm-setup
  .\export.ps1
  .\export.ps1 -SkipFonts
#>
[CmdletBinding()]
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
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$ok = 0
$missing = 0

function Expand-TargetPath([string]$Template) {
  $expanded = $ExecutionContext.InvokeCommand.ExpandString($Template)
  return [Environment]::ExpandEnvironmentVariables($expanded)
}

Write-Host "export  $stamp" -ForegroundColor Cyan
Write-Host "repo    $RepoRoot"
Write-Host ""

# --- config files ---
foreach ($entry in $Map.Files) {
  $srcRel = $entry.Source -replace '/', [IO.Path]::DirectorySeparatorChar
  $dest = Join-Path $RepoRoot $srcRel
  $live = Expand-TargetPath $entry.Target

  if (-not (Test-Path -LiteralPath $live)) {
    Write-Host "  MISS  $live" -ForegroundColor Yellow
    $missing++
    continue
  }

  $destDir = Split-Path -Parent $dest
  if (-not (Test-Path -LiteralPath $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }

  Copy-Item -LiteralPath $live -Destination $dest -Force
  Write-Host "  OK    $live" -ForegroundColor Green
  Write-Host "     -> $($entry.Source)"
  $ok++
}

# --- fonts (Mono family only) ---
if (-not $SkipFonts) {
  Write-Host ""
  Write-Host "fonts" -ForegroundColor Cyan
  $fontSrcPattern = $Map.Fonts.Pattern
  $userFontDir = Expand-TargetPath $Map.Fonts.TargetDir
  $repoFontDir = Join-Path $RepoRoot ($Map.Fonts.SourceDir -replace '/', [IO.Path]::DirectorySeparatorChar)

  if (-not (Test-Path -LiteralPath $repoFontDir)) {
    New-Item -ItemType Directory -Force -Path $repoFontDir | Out-Null
  }

  $found = @()
  if (Test-Path -LiteralPath $userFontDir) {
    $found += Get-ChildItem -LiteralPath $userFontDir -Filter $fontSrcPattern -File -ErrorAction SilentlyContinue
  }
  $systemFonts = Join-Path $env:WINDIR 'Fonts'
  if (Test-Path -LiteralPath $systemFonts) {
    $found += Get-ChildItem -LiteralPath $systemFonts -Filter $fontSrcPattern -File -ErrorAction SilentlyContinue
  }

  # Dedupe by name
  $found = $found | Sort-Object Name -Unique

  if (-not $found -or $found.Count -eq 0) {
    Write-Host "  MISS  no files matching $fontSrcPattern" -ForegroundColor Yellow
    Write-Host "        looked in: $userFontDir"
    Write-Host "                    $systemFonts"
    $missing++
  }
  else {
    foreach ($f in $found) {
      Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $repoFontDir $f.Name) -Force
      Write-Host "  OK    $($f.Name)" -ForegroundColor Green
      $ok++
    }
  }
}
else {
  Write-Host ""
  Write-Host "fonts  skipped (-SkipFonts)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "done  copied=$ok  missing=$missing" -ForegroundColor Cyan
if ($missing -gt 0) { exit 1 }
