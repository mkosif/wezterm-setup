# wezterm-setup

Personal WezTerm bootstrap for my machines only (private repo).

Copies config in and out of the live paths WezTerm actually reads. Themes (OLED Soft, Day, Catppuccin, Tokyo Night, Nord, …) live **inside** `wezterm.lua` — there is no separate theme pack. Per-machine last-selected theme (`~/.wezterm-theme-index`) is **not** synced.

## Layout

```text
files/                 tracked config (export/import)
fonts/JetBrainsMonoNerdFontMono/   Mono family only (~what WezTerm uses)
files.map.psd1         source ↔ target map
export.ps1             live machine → repo
import.ps1             repo → live machine (+ backup + user font install)
```

## Live paths

| Repo | Machine |
|------|---------|
| `files/wezterm.lua` | `~/.wezterm.lua` |
| `files/wezterm-pwsh.ps1` | `~/config/wezterm-pwsh.ps1` |
| `files/wezterm-keys.md` | `~/config/wezterm-keys.md` |
| `files/powershell-profile-snippet.ps1` | `~/config/powershell-profile-snippet.ps1` |

## New machine

```powershell
git clone git@github.com:mkosif/wezterm-setup.git $HOME\work\wezterm-setup
cd $HOME\work\wezterm-setup
.\import.ps1
# Restart WezTerm
```

- Existing targets are copied to `*.bak-yyyyMMdd-HHmmss` before overwrite.
- Fonts install to `%LOCALAPPDATA%\Microsoft\Windows\Fonts` + HKCU (no admin).
- WezTerm itself is **not** installed by these scripts.

```powershell
.\import.ps1 -SkipFonts   # config only
.\import.ps1 -WhatIf      # dry run
```

## Update repo from a tuned machine

```powershell
cd $HOME\work\wezterm-setup
.\export.ps1
git add -A
git status
git commit -m "Sync WezTerm config"
git push
```

```powershell
.\export.ps1 -SkipFonts
```

## Assumptions (warnings on import)

- PowerShell 7 at `C:\Program Files\PowerShell\7\pwsh.exe`
- Default cwd `~/work`
- Font family name: `JetBrainsMono Nerd Font Mono`

## Not included

- Icon / exe patch tooling
- Theme index state
- Full Nerd Font download (Propo, NL, non-Mono) — only Mono `*.ttf` used by this config
