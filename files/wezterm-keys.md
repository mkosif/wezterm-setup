# WezTerm + shell shortcuts

Type **`keys`** in the terminal anytime to print this guide.

This WezTerm is **Grok-focused** (Kitty keyboard, Grok chords not stolen).
Startup opens Grok. **New tab** (`Ctrl+Shift+T` or **+**) is a normal `pwsh` shell.

Leader = **Ctrl+Shift+Space** (press, release, then the next key).
`Ctrl+Space` is left alone — that is PSReadLine completion.

## Shell commands

| Command | What it does |
|--------|----------------|
| `keys` / `helpme` | Show this cheatsheet |
| `grok` / `gg` | Run Grok **in this tab** |
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

## WezTerm — keys

| Keys | Action |
|------|--------|
| `Ctrl+C` | Copy if text is selected, otherwise interrupt |
| `Ctrl+V` | Goes to the app (Grok image paste / PSReadLine) |
| `Ctrl+Shift+C` / `V` | Host copy / paste |
| `Ctrl+Shift+T` / **+** | New **shell** tab |
| `Ctrl+Shift+G` | New **Grok** tab |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+Shift+N` | New window (starts Grok) |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / prev tab |
| `Ctrl+Shift+F` | Search scrollback |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+Shift+L` | Launch menu |
| `Ctrl+Shift+Q` | Quick select (URLs, paths…) |
| `Ctrl+Shift+,` | Open `.wezterm.lua` |
| `Ctrl+Shift+R` | Reload config |
| `Ctrl` `+` / `-` / `0` | Font bigger / smaller / reset |
| `Alt+Shift+D` | Split right |
| `Alt+Shift+-` | Split down |
| `Alt` arrows | Focus pane |
| `F11` | Fullscreen |
| `Alt+1`…`9` | Jump to tab N |

## WezTerm — Leader (Ctrl+Shift+Space then …)

| Key | Action |
|-----|--------|
| `-` or `s` | Split down |
| `\` or `v` | Split right |
| `h` `j` `k` `l` | Focus pane |
| `x` | Close pane |
| `z` | Zoom pane |
| `p` | Pane picker |
| `r` | Resize mode (arrows/hjkl, Esc done) |
| `Space` | Rotate panes |
| `e` | Open folder in Explorer |
| `y` | Copy path to clipboard |
| `g` | lazygit in new tab |
| `G` | New Grok tab |
| `t` | Cycle theme (Soft / Day / …) |
| `o` | Toggle opacity (prefer off on OLED) |
| `Enter` | Zen mode (hide tab bar) |
| `c` | Clear scrollback |
| `?` | Run `keys` (this help) |

## Mouse

| Action | What |
|--------|------|
| Select text | Select (copy with `Ctrl+C`) |
| Right-click | Paste |
| Ctrl+click | Open link |

## Tips

- New tab inherits the current folder after OSC 7 fires (after the first prompt).
- Status bar = folder name + time.
- Window chrome is the real Windows title bar (min/max/close). Tab bar is below it.
- Grok chords stay in the PTY: `Ctrl+Enter`, `Shift+Enter`, `Alt+V`, `Ctrl+N`, `Ctrl+V`.
