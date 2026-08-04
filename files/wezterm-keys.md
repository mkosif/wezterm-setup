# WezTerm + shell shortcuts

Type **`keys`** in the terminal anytime to print this guide.

Leader = **Ctrl+Space** (press, release, then the next key)

## Shell commands

| Command | What it does |
|--------|----------------|
| `keys` / `helpme` | Show this cheatsheet |
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

## WezTerm — Ctrl+Shift

| Keys | Action |
|------|--------|
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+Shift+N` | New window |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / prev tab |
| `Ctrl+Shift+C` / `V` | Copy / paste |
| `Ctrl+Shift+F` | Search scrollback |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+Shift+L` | Launch menu (shells) |
| `Ctrl+Shift+Q` | Quick select (URLs, paths…) |
| `Ctrl+Shift+,` | Open `.wezterm.lua` |
| `Ctrl+Shift+R` | Reload config |
| `Ctrl +` / `-` / `0` | Font bigger / smaller / reset |
| `F11` | Fullscreen |
| `Alt+1`…`9` | Jump to tab N |

## WezTerm — Leader (Ctrl+Space then …)

| Key | Action |
|-----|--------|
| `-` or `s` | Split horizontal (top/bottom) |
| `\` or `v` | Split vertical (left/right) |
| `h` `j` `k` `l` | Focus pane (vim) |
| `x` | Close pane |
| `z` | Zoom pane |
| `p` | Pane picker |
| `r` | Resize mode (arrows/hjkl, Esc done) |
| `Space` | Rotate panes |
| `e` | Open folder in Explorer |
| `y` | Copy path to clipboard |
| `g` | lazygit in new tab |
| `t` | Cycle theme (Soft / Day / …) |
| `o` | Toggle opacity (prefer off on OLED) |
| `Enter` | Zen mode (hide tab bar) |
| `c` | Clear scrollback |
| `?` | Run `keys` (this help) |

## Mouse

| Action | What |
|--------|------|
| Select text | Auto-copy |
| Right-click | Paste |
| Ctrl+click | Open link |
| Triple-click | Select semantic zone |

## Tips

- New tab inherits current folder (after you press Enter once so OSC 7 fires).
- Status bar top-right = folder name + time (not “workspace name”).
- Pin **Desktop → WezTerm** shortcut for the custom taskbar icon.
