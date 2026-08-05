# New Windows 11 machine

One-shot bootstrap for **PowerShell 7**, **WezTerm**, **JetBrainsMono Nerd Font Mono**, and this repo’s config.

Works on a stock Win11 install that only has **Windows PowerShell 5.1**.

---

## Prerequisites

| Need | Notes |
|------|--------|
| Internet | winget / GitHub MSI download |
| Git | optional if you copy the repo another way |
| winget | usually preinstalled (App Installer from Store if missing) |
| Admin (UAC) | only if winget cannot install PS7 and MSI fallback runs |

You do **not** need PowerShell 7 already installed to run the scripts.

---

## Quick path (recommended)

In **Windows PowerShell** or **Terminal** (5.1 is fine):

```powershell
# 1) Folders
New-Item -ItemType Directory -Force -Path $HOME\work | Out-Null

# 2) Clone (HTTPS works without SSH keys)
git clone https://github.com/mkosif/wezterm-setup.git $HOME\work\wezterm-setup
cd $HOME\work\wezterm-setup

# 3) Allow local scripts once if needed
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# 4) Bootstrap everything
.\setup.ps1
```

Then:

1. Fully quit WezTerm (system tray too).
2. Start WezTerm.
3. Check:

```powershell
$PSVersionTable.PSVersion    # major should be 7
$PSVersionTable.PSEdition    # Core
```

4. Type `keys` for the shortcut cheatsheet.

---

## What `setup.ps1` does (in order)

| Step | Script | Effect |
|------|--------|--------|
| 0 | (inline) | Creates `~\work`, `~\config`, `~\tools`, `~\tmp` if missing |
| 1 | `scripts\Install-Pwsh.ps1` | Installs **PowerShell 7** (`pwsh`) if missing |
| 2 | `scripts\Install-WezTerm.ps1` | Installs **WezTerm** if missing |
| 3 | `scripts\Install-Fonts.ps1` | Installs **JetBrainsMono Nerd Font Mono** (per-user, no admin) |
| 4 | `import.ps1 -SkipFonts` | Copies config → `~\.wezterm.lua`, `~\config\…` |
| 5 | `scripts\Verify-Setup.ps1` | Fails the run if critical pieces are missing |

Idempotent: run again anytime after upgrades or a broken machine.

### Flags

```powershell
.\setup.ps1 -SkipWezTerm     # you already installed WezTerm
.\setup.ps1 -SkipPwsh        # pwsh already OK
.\setup.ps1 -SkipFonts
.\setup.ps1 -SkipImport      # only install tools/fonts
.\setup.ps1 -SkipVerify
```

---

## PowerShell 7 details

### Why it is required

`wezterm.lua` sets the **default shell** to PowerShell 7 (`pwsh`), not Windows PowerShell 5.1.

Resolution order (first file that exists wins):

1. `%ProgramFiles%\PowerShell\7\pwsh.exe` (winget / MSI default)
2. `%ProgramW6432%\PowerShell\7\pwsh.exe`
3. `C:\Program Files\PowerShell\7\pwsh.exe`
4. `%LOCALAPPDATA%\PowerShell\7\pwsh.exe`
5. `~\scoop\apps\pwsh\current\pwsh.exe`

### Install only PS7

```powershell
cd $HOME\work\wezterm-setup
.\scripts\Install-Pwsh.ps1
```

Strategy:

1. If `pwsh` already exists → ensure User **PATH**, exit OK  
2. Else **winget**: `Microsoft.PowerShell`  
3. Else **GitHub MSI** (latest `*-win-x64.msi`, may prompt UAC)  
4. Refuse to report success unless `pwsh.exe` is found afterward  

```powershell
.\scripts\Install-Pwsh.ps1 -SkipMsiFallback   # winget only
```

### “Default” meaning here

| Context | Behavior |
|---------|----------|
| **WezTerm new tab / window** | PowerShell 7 + loads `~\config\wezterm-pwsh.ps1` |
| **Launch menu** | “PowerShell 7” entry uses the same binary |
| **Windows PowerShell 5.1** | Still installed by the OS; unchanged |
| **Win+X / other apps** | Not rewritten (on purpose) |

Making PS7 the shell **inside WezTerm** is the goal of this repo.

---

## Font details

### What gets installed

Bundled under:

```text
fonts/JetBrainsMonoNerdFontMono/JetBrainsMonoNerdFontMono-*.ttf
```

Installed for the **current user** only:

- Files → `%LOCALAPPDATA%\Microsoft\Windows\Fonts\`
- Registry → `HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts`
- Best-effort `AddFontResourceEx` so a full logoff is often unnecessary

### What WezTerm selects

In `wezterm.lua` (already set — you do not pick a font in a GUI):

```text
JetBrainsMono Nerd Font Mono     ← primary
JetBrainsMono Nerd Font
JetBrains Mono
Cascadia Code / Cascadia Mono
Segoe UI Emoji
```

Install fonts only:

```powershell
.\scripts\Install-Fonts.ps1
```

If icons look like boxes:

1. Confirm Verify sees the family: `.\scripts\Verify-Setup.ps1`
2. Fully quit WezTerm and reopen  
3. Worst case: sign out of Windows once  

---

## Config import only

If tools/fonts are already installed:

```powershell
cd $HOME\work\wezterm-setup
.\import.ps1
```

Live targets (from `files.map.psd1`):

| Repo | Machine |
|------|---------|
| `files/wezterm.lua` | `~\.wezterm.lua` |
| `files/wezterm-pwsh.ps1` | `~\config\wezterm-pwsh.ps1` |
| `files/wezterm-keys.md` | `~\config\wezterm-keys.md` |
| `files/powershell-profile-snippet.ps1` | `~\config\powershell-profile-snippet.ps1` |

Existing files are backed up as `*.bak-yyyyMMdd-HHmmss`.

---

## Verify anytime

```powershell
cd $HOME\work\wezterm-setup
.\scripts\Verify-Setup.ps1
```

Critical failures (exit 1): missing `pwsh`, missing font files, missing live config paths.

---

## Manual fallbacks (if automation cannot run)

### PowerShell 7

```powershell
winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
```

Or: https://aka.ms/powershell-release?tag=stable  

### WezTerm

```powershell
winget install --id wez.wezterm -e --accept-package-agreements --accept-source-agreements
```

Or: https://wezfurlong.org/wezterm/install/windows.html  

### Fonts

Run `.\scripts\Install-Fonts.ps1`, or copy the TTFs from `fonts\JetBrainsMonoNerdFontMono\` into  
`%LOCALAPPDATA%\Microsoft\Windows\Fonts` and register them (script does this correctly).

---

## Optional tools (not installed by setup)

These improve the shell snippet but are **not required**:

- zoxide, eza, bat, fzf, fd, lazygit, ripgrep  

Install later via winget/scoop as you like. Missing tools are skipped by `wezterm-pwsh.ps1`.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| WezTerm tab closes immediately | PS7 missing → `.\scripts\Install-Pwsh.ps1` |
| `pwsh` works in one terminal but not WezTerm | Fully restart WezTerm; run `Verify-Setup.ps1` |
| Boxes instead of icons | `.\scripts\Install-Fonts.ps1`, restart WezTerm |
| winget not found | Microsoft Store → **App Installer** |
| Execution policy blocks scripts | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| MSI UAC cancelled | Approve UAC, or install PS7 via winget manually |
| `~/work` missing | Created by `setup.ps1`; or `mkdir $HOME\work` |

---

## Update config from a tuned machine

```powershell
cd $HOME\work\wezterm-setup
.\export.ps1
git add -A
git status
git commit -m "Sync WezTerm config"
git push
```

On the other PC: `git pull` then `.\import.ps1` or `.\setup.ps1`.
