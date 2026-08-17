# WezTerm + shell shortcuts

Type **`keys`** in the terminal anytime to print this guide.

WezTerm opens as a **normal shell** (`pwsh`). Run Grok yourself: `grok` or `gg`.

---

## Shell commands

| Command | What it does |
|--------|----------------|
| `keys` / `helpme` | Show this cheatsheet |
| `grok` / `gg` | Start Grok in this tab |
| `z <name>` | Jump to a frecent folder (zoxide) |
| `zi` | Interactive folder pick (fzf) |
| `ll` | Long list (eza) |
| `ls` | List (eza) |
| `lt` | Tree depth 2 (eza) |
| `cat <file>` | View file (bat) |
| `ww` | Go to `~\work` |
| `home` | Go to user profile |
| `..` / `...` | Up 1 / up 2 dirs |
| `o` | Open cwd in Explorer |
| `cpath` | Copy cwd to clipboard |
| `lg` | lazygit |
| `ff <query>` | Search with ripgrep |
| `fdf <query>` | Find files with fd |
| `boot` | Copy AI BOOTSTRAP.md to clipboard |

## WezTerm keys

| Keys | Action |
|------|--------|
| `Ctrl+C` | Copy if selection, else interrupt |
| `Ctrl+V` | To the app (Grok paste / PSReadLine) |
| `Ctrl+Shift+C` / `V` | Host copy / paste |
| `Ctrl+Shift+T` | New shell tab |
| `Ctrl+Shift+N` | New window (shell) |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / prev tab |
| `Ctrl+Shift+F` | Search scrollback |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+Shift+L` | Launch menu |
| `Ctrl+Shift+Q` | Quick select |
| `Ctrl+Shift+,` | Open `.wezterm.lua` |
| `Ctrl+Shift+R` | Reload config |
| `Ctrl` `+` / `-` / `0` | Font size |
| `Alt+Shift+D` | Split right |
| `Alt+Shift+-` | Split down |
| `Alt+Shift+Z` | Zoom pane |
| `Alt` arrows | Focus pane |
| `F11` | Fullscreen |
| `Alt+1`…`9` | Jump to tab N |

## Mouse

| Action | What |
|--------|------|
| Select text | (use Ctrl+Shift+C or Ctrl+C to copy) |
| Right-click | Paste |
| Ctrl+click | Open link |

## Grok tips

- Start shell → type `grok` (or `gg`).
- Host does **not** steal `Ctrl+Enter`, `Ctrl+V`, `Shift+Enter`.
- Kitty keyboard protocol is on (WezTerm ↔ Grok).

## Notes

- No leader key, no theme cycle, no auto-start Grok.
- Single OLED theme, steady cursor (no blink).
- Cursor in Grok may still animate if the TUI draws it — that is Grok, not WezTerm.
