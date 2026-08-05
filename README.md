# wezterm-setup

Personal WezTerm bootstrap (Windows 11): OLED-friendly config, PowerShell 7 default shell, JetBrainsMono Nerd Font Mono.

**Public repo:** https://github.com/mkosif/wezterm-setup

Themes (OLED Soft, Day, Catppuccin, Tokyo Night, Nord, …) live **inside** `wezterm.lua`. Per-machine last theme (`~\.wezterm-theme-index`) is **not** synced.

---

## New machine (start here)

Full guide: **[docs/NEW-MACHINE.md](docs/NEW-MACHINE.md)**

```powershell
git clone https://github.com/mkosif/wezterm-setup.git $HOME\work\wezterm-setup
cd $HOME\work\wezterm-setup
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned   # once, if needed
.\setup.ps1
# Fully quit WezTerm → reopen → $PSVersionTable.PSVersion should be 7.x
```

`setup.ps1` (idempotent):

1. Creates `~\work`, `~\config`, …  
2. **Installs PowerShell 7** if missing (`scripts\Install-Pwsh.ps1`)  
3. **Installs WezTerm** if missing (`scripts\Install-WezTerm.ps1`)  
4. **Installs Nerd Font Mono** for the current user (`scripts\Install-Fonts.ps1`)  
5. **Imports config** (`import.ps1`)  
6. **Verifies** (`scripts\Verify-Setup.ps1`)  

Runs on stock **Windows PowerShell 5.1** (no PS7 required beforehand).

### Individual scripts

| Script | Purpose |
|--------|---------|
| `setup.ps1` | Full bootstrap |
| `scripts\Install-Pwsh.ps1` | Install / locate `pwsh`, User PATH |
| `scripts\Install-WezTerm.ps1` | Install WezTerm via winget |
| `scripts\Install-Fonts.ps1` | Install bundled JetBrainsMono Nerd Font Mono |
| `scripts\Verify-Setup.ps1` | Health check (exit 1 on hard failures) |
| `import.ps1` | Repo → live paths (+ optional fonts) |
| `export.ps1` | Live paths → repo |

```powershell
.\scripts\Install-Pwsh.ps1
.\scripts\Install-Fonts.ps1
.\scripts\Verify-Setup.ps1
.\import.ps1 -SkipFonts
.\setup.ps1 -SkipWezTerm
```

---

## Layout

```text
setup.ps1                 full bootstrap (new PC)
import.ps1 / export.ps1   config sync
files.map.psd1            source ↔ target map
files/                    tracked config
fonts/JetBrainsMonoNerdFontMono/   Mono family only
scripts/                  install + verify helpers
docs/NEW-MACHINE.md       detailed new-machine guide
```

## Live paths

| Repo | Machine |
|------|---------|
| `files/wezterm.lua` | `~\.wezterm.lua` |
| `files/wezterm-pwsh.ps1` | `~\config\wezterm-pwsh.ps1` |
| `files/wezterm-keys.md` | `~\config\wezterm-keys.md` |
| `files/powershell-profile-snippet.ps1` | `~\config\powershell-profile-snippet.ps1` |

## Defaults after setup

| Item | Value |
|------|--------|
| Default shell (WezTerm) | PowerShell 7 (`pwsh`) |
| Shell init | `~\config\wezterm-pwsh.ps1` |
| Font | `JetBrainsMono Nerd Font Mono` (with fallbacks) |
| Default cwd | `~\work` |

## Update repo from a tuned machine

```powershell
cd $HOME\work\wezterm-setup
.\export.ps1
git add -A
git status
git commit -m "Sync WezTerm config"
git push
```

## Not included

- Optional CLIs (zoxide, eza, bat, lazygit, …) — install yourself; snippet skips missing ones  
- Icon / exe patch tooling  
- Theme index state  
- Full Nerd Font zip (only Mono `*.ttf` used by this config)  
