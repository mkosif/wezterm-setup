#Requires -Version 5.1
# Shared helpers for wezterm-setup install scripts.
# Dot-source only:  . "$PSScriptRoot\lib.ps1"
# Do not set StrictMode here - callers (import.ps1) may not expect it.

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
  param([string]$Message)
  Write-Host "  OK    $Message" -ForegroundColor Green
}

function Write-Warn {
  param([string]$Message)
  Write-Host "  WARN  $Message" -ForegroundColor Yellow
}

function Write-Fail {
  param([string]$Message)
  Write-Host "  FAIL  $Message" -ForegroundColor Red
}

function Write-Info {
  param([string]$Message)
  Write-Host "  ..    $Message" -ForegroundColor DarkGray
}

# Capture at load time (reliable after dot-sourcing from import.ps1 or setup.ps1).
$script:WezSetupScriptsDir = $PSScriptRoot
$script:WezSetupRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Get-RepoRoot {
  return $script:WezSetupRepoRoot
}

function Test-IsAdministrator {
  try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }
  catch {
    return $false
  }
}

function Get-PwshCandidates {
  <#
    Ordered list of places PowerShell 7 is commonly installed.
    First existing path wins in Resolve-PwshPath.
  #>
  $list = New-Object System.Collections.Generic.List[string]

  $add = {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $full = [Environment]::ExpandEnvironmentVariables($Path)
    if (-not $list.Contains($full)) { [void]$list.Add($full) }
  }

  # Machine-wide (winget / MSI default)
  & $add (Join-Path ${env:ProgramFiles} 'PowerShell\7\pwsh.exe')
  if ($env:ProgramW6432) {
    & $add (Join-Path $env:ProgramW6432 'PowerShell\7\pwsh.exe')
  }
  & $add 'C:\Program Files\PowerShell\7\pwsh.exe'

  # Store / user-local (less common; still valid full binary)
  if ($env:LOCALAPPDATA) {
    & $add (Join-Path $env:LOCALAPPDATA 'PowerShell\7\pwsh.exe')
  }

  # Scoop
  if ($env:USERPROFILE) {
    & $add (Join-Path $env:USERPROFILE 'scoop\apps\pwsh\current\pwsh.exe')
  }

  # Whatever is on PATH (may be shim) - last so real installs win first
  $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) {
    & $add $cmd.Source
  }

  return , $list.ToArray()
}

function Resolve-PwshPath {
  <#
    Returns full path to pwsh.exe if found, otherwise $null.
  #>
  foreach ($p in (Get-PwshCandidates)) {
    if (Test-Path -LiteralPath $p) {
      return $p
    }
  }
  return $null
}

function Get-PreferredPwshPath {
  # Path WezTerm config prefers (machine-wide MSI/winget).
  return (Join-Path ${env:ProgramFiles} 'PowerShell\7\pwsh.exe')
}

function Test-WingetAvailable {
  $w = Get-Command winget.exe -ErrorAction SilentlyContinue
  return [bool]$w
}

function Invoke-WingetInstall {
  param(
    [Parameter(Mandatory)]
    [string]$PackageId,
    [string]$DisplayName = $PackageId
  )

  if (-not (Test-WingetAvailable)) {
    return @{ Ok = $false; Reason = 'winget not on PATH' }
  }

  Write-Info "winget install $PackageId"
  $args = @(
    'install',
    '--id', $PackageId,
    '-e',
    '--source', 'winget',
    '--accept-package-agreements',
    '--accept-source-agreements',
    '--disable-interactivity'
  )

  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $output = & winget @args 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev

  if ($output) {
    $output | ForEach-Object { Write-Info ("winget: " + ($_ | Out-String).TrimEnd()) }
  }

  # 0 = success
  # -1978335189 (0x8A15002B) = already installed
  # -1978335212 (0x8A150014) = no newer version / no applicable upgrade
  $okCodes = @(0, -1978335189, -1978335212)
  if ($okCodes -contains $code) {
    return @{ Ok = $true; ExitCode = $code; AlreadyPresent = ($code -ne 0) }
  }

  return @{
    Ok       = $false
    ExitCode = $code
    Reason   = "winget exit $code for $DisplayName"
  }
}

function Update-UserPathEntry {
  <#
    Append $Dir to the user PATH if missing. Returns $true if PATH was changed.
  #>
  param(
    [Parameter(Mandatory)]
    [string]$Dir
  )

  if (-not (Test-Path -LiteralPath $Dir)) {
    return $false
  }

  $dirFull = [IO.Path]::GetFullPath($Dir)
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($null -eq $userPath) { $userPath = '' }

  $parts = $userPath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' }
  foreach ($p in $parts) {
    try {
      if ([IO.Path]::GetFullPath($p) -eq $dirFull) {
        return $false
      }
    }
    catch {
      if ($p -eq $dirFull) { return $false }
    }
  }

  $newPath = if ($userPath.TrimEnd(';') -eq '') { $dirFull } else { $userPath.TrimEnd(';') + ';' + $dirFull }
  [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')

  # Current process too
  if ($env:Path -notlike "*$dirFull*") {
    $env:Path = $env:Path.TrimEnd(';') + ';' + $dirFull
  }
  return $true
}

function Install-UserFontFile {
  <#
    Per-user font install (no admin):
      %LOCALAPPDATA%\Microsoft\Windows\Fonts + HKCU Fonts key
    Also calls AddFontResourceEx so the session can see it without logoff.
  #>
  param(
    [Parameter(Mandatory)]
    [string]$TtfPath
  )

  if (-not (Test-Path -LiteralPath $TtfPath)) {
    throw "Font file missing: $TtfPath"
  }

  $name = [IO.Path]::GetFileName($TtfPath)
  $destDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  if (-not (Test-Path -LiteralPath $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }

  $dest = Join-Path $destDir $name

  # Idempotent copy: skip if identical; if locked by WezTerm/explorer, keep existing.
  $needCopy = $true
  if (Test-Path -LiteralPath $dest) {
    try {
      $srcHash = (Get-FileHash -LiteralPath $TtfPath -Algorithm SHA256).Hash
      $dstHash = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
      if ($srcHash -eq $dstHash) { $needCopy = $false }
    }
    catch {
      $needCopy = $true
    }
  }

  if ($needCopy) {
    try {
      Copy-Item -LiteralPath $TtfPath -Destination $dest -Force -ErrorAction Stop
    }
    catch {
      if (Test-Path -LiteralPath $dest) {
        # Another process (often wezterm) has the TTF open; existing file is good enough.
        Write-Warn "font file locked, keeping existing: $name"
      }
      else {
        throw
      }
    }
  }

  $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  if (-not (Test-Path -LiteralPath $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
  }
  # Value name is free-form; absolute path required for per-user fonts.
  $valueName = "$name (TrueType)"
  New-ItemProperty -Path $regPath -Name $valueName -Value $dest -PropertyType String -Force | Out-Null

  # Load into this session (best-effort; ignore failures)
  try {
    if (-not ('WezSetup.FontNative' -as [type])) {
      Add-Type -Namespace WezSetup -Name FontNative -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("gdi32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
public static extern int AddFontResourceEx(string lpszFilename, uint fl, System.IntPtr pdv);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern int SendMessageTimeout(System.IntPtr hWnd, uint Msg, System.IntPtr wParam, System.IntPtr lParam, uint fuFlags, uint uTimeout, out System.IntPtr lpdwResult);
'@
    }
    # FR_PRIVATE is 0x10; we want public for apps -> flags 0
    [void][WezSetup.FontNative]::AddFontResourceEx($dest, 0, [IntPtr]::Zero)
    $hwndBroadcast = [IntPtr]0xffff
    $WM_FONTCHANGE = [uint32]0x001D
    $result = [IntPtr]::Zero
    [void][WezSetup.FontNative]::SendMessageTimeout(
      $hwndBroadcast, $WM_FONTCHANGE, [IntPtr]::Zero, [IntPtr]::Zero,
      0x0000, 1000, [ref]$result
    )
  }
  catch {
    # Non-fatal: logoff/reboot or app restart still picks fonts up from registry.
  }

  return $dest
}

function Ensure-HomeDirs {
  param(
    [string[]]$Relative = @('work', 'config', 'tools', 'tmp')
  )
  foreach ($r in $Relative) {
    $p = Join-Path $env:USERPROFILE $r
    if (-not (Test-Path -LiteralPath $p)) {
      New-Item -ItemType Directory -Force -Path $p | Out-Null
      Write-Ok "created ~\$r"
    }
  }
}

function Get-Map {
  $repo = Get-RepoRoot
  $mapPath = Join-Path $repo 'files.map.psd1'
  if (-not (Test-Path -LiteralPath $mapPath)) {
    throw "Missing map: $mapPath"
  }
  return Import-PowerShellDataFile -Path $mapPath
}
