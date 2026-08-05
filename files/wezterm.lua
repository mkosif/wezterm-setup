local wezterm = require("wezterm")
local act = wezterm.action

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local is_windows = wezterm.target_triple:find("windows") ~= nil
local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
local work_root = home .. "\\work"

-- Resolve PowerShell 7 on this machine (winget/MSI standard path first, then scoop).
-- Install via:  .\scripts\Install-Pwsh.ps1   or   .\setup.ps1
local function file_exists(path)
  if not path or path == "" then
    return false
  end
  local f = io.open(path, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

local function resolve_pwsh()
  local candidates = {}
  local function add(p)
    if p and p ~= "" then
      table.insert(candidates, p)
    end
  end
  local pf = os.getenv("ProgramFiles")
  local pf64 = os.getenv("ProgramW6432")
  local localapp = os.getenv("LOCALAPPDATA")
  add(pf and (pf .. "\\PowerShell\\7\\pwsh.exe"))
  add(pf64 and (pf64 .. "\\PowerShell\\7\\pwsh.exe"))
  add("C:\\Program Files\\PowerShell\\7\\pwsh.exe")
  add(localapp and (localapp .. "\\PowerShell\\7\\pwsh.exe"))
  add(home .. "\\scoop\\apps\\pwsh\\current\\pwsh.exe")
  for _, p in ipairs(candidates) do
    if file_exists(p) then
      return p
    end
  end
  -- Prefer standard path in error cases (Install-Pwsh puts it here).
  return "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
end

local pwsh = is_windows and resolve_pwsh() or "pwsh"
-- Documents\\PowerShell profile is often blocked by Controlled Folder Access;
-- load OLED FileInfo colors from ~/config instead.
local pwsh_oled = home .. "\\config\\wezterm-pwsh.ps1"
local default_shell = is_windows
    and {
      pwsh,
      "-NoLogo",
      "-NoExit",
      "-Command",
      (". \"" .. pwsh_oled .. "\""),
    }
  or { os.getenv("SHELL") or "sh", "-l" }

-- OLED visual rules (all themes):
-- * UI chrome bg is pure #000000 (pixel-off → less battery, less smear)
-- * fg is soft-white (night: less glare) but still high luminance (day: readable)
-- * dim/muted have a luminance floor so low system brightness stays legible
-- * accents stay bright; selection is clearly visible on black
local themes = {
  {
    -- Default: night-friendly, still OK outdoors with font size 13
    label = "OLED Soft (Dracula)",
    scheme = "Dracula (Official)",
    bg_alt = "#000000",
    bg_deep = "#000000",
    fg = "#e8e6f0",
    muted = "#b7a8d4",
    dim = "#8f82ab",
    blue = "#8be9fd",
    cyan = "#80ffea",
    green = "#69ff94",
    yellow = "#f1fa8c",
    purple = "#d6acff",
    selection = "#3d3f5c",
  },
  {
    -- Punchier text for sun / high ambient light (Ctrl+Space then t)
    label = "OLED Day (High Contrast)",
    scheme = "Dracula (Official)",
    bg_alt = "#000000",
    bg_deep = "#000000",
    fg = "#f5f5f7",
    muted = "#d0d0d8",
    dim = "#a8a8b4",
    blue = "#9aefff",
    cyan = "#9dffe8",
    green = "#7dff9a",
    yellow = "#ffe66d",
    purple = "#e0b0ff",
    selection = "#4a4d6a",
  },
  {
    label = "OLED Catppuccin",
    scheme = "Catppuccin Mocha",
    bg_alt = "#000000",
    bg_deep = "#000000",
    fg = "#e0e6f8",
    muted = "#b4bcd0",
    dim = "#8b93a8",
    blue = "#89b4fa",
    cyan = "#94e2d5",
    green = "#a6e3a1",
    yellow = "#f9e2af",
    purple = "#cba6f7",
    selection = "#3b3f54",
  },
  {
    label = "OLED Tokyo Night",
    scheme = "Tokyo Night",
    bg_alt = "#000000",
    bg_deep = "#000000",
    fg = "#d0d8f8",
    muted = "#a8b2d8",
    dim = "#8892b8",
    blue = "#7aa2f7",
    cyan = "#7dcfff",
    green = "#9ece6a",
    yellow = "#e0af68",
    purple = "#bb9af7",
    selection = "#2f3b5c",
  },
  {
    label = "OLED Nord",
    scheme = "Nord (Gogh)",
    bg_alt = "#000000",
    bg_deep = "#000000",
    fg = "#e5e9f0",
    muted = "#b8c0cc",
    dim = "#8f99a8",
    blue = "#88c0d0",
    cyan = "#8fbcbb",
    green = "#a3be8c",
    yellow = "#ebcb8b",
    purple = "#b48ead",
    selection = "#3b4252",
  },
}

local default_theme_index = 1
local theme_state_path = home .. "\\.wezterm-theme-index"

local function load_theme_index()
  local f = io.open(theme_state_path, "r")
  if not f then
    return default_theme_index
  end
  local content = f:read("*a")
  f:close()
  local n = tonumber((content or ""):match("%d+"))
  if n and n >= 1 and n <= #themes then
    return n
  end
  return default_theme_index
end

local function save_theme_index(index)
  local f = io.open(theme_state_path, "w")
  if not f then
    return
  end
  f:write(tostring(index))
  f:close()
end

wezterm.GLOBAL.kosif_theme_index = wezterm.GLOBAL.kosif_theme_index or load_theme_index()

local function active_theme()
  return themes[wezterm.GLOBAL.kosif_theme_index] or themes[default_theme_index]
end

local function theme_overrides(theme)
  -- Pure black everywhere we can: OLED pixels stay off under empty chrome.
  --
  -- ANSI 4 (blue) and 6 (cyan) must NOT be pastel-light: PowerShell colors
  -- directories as white-on-blue (bg=ansi4). Light cyan bg + light fg = unreadable.
  -- Keep blues/cyans mid-dark so they work as background AND as foreground.
  return {
    foreground = theme.fg,
    background = "#000000",
    cursor_bg = theme.yellow,
    cursor_border = theme.yellow,
    cursor_fg = "#000000",
    selection_bg = theme.selection,
    selection_fg = theme.fg,
    scrollbar_thumb = theme.dim,
    split = theme.dim,
    ansi = {
      "#000000", -- 0 black
      "#e84a5f", -- 1 red
      "#3dd68c", -- 2 green
      "#d4b84a", -- 3 yellow (not neon; readable)
      "#1f6feb", -- 4 blue  ← PS directory background; white-on-this must be OK
      "#a371f7", -- 5 magenta
      "#1a7f8c", -- 6 cyan  ← mid teal if anything uses cyan bg
      theme.fg,  -- 7 white
    },
    brights = {
      theme.dim, -- 8
      "#ff7b8a", -- 9
      "#56f0a0", -- 10 green bright (headers, timestamps)
      "#f0d66a", -- 11
      "#79c0ff", -- 12 bright blue (FG accents / links)
      "#d2a8ff", -- 13
      "#56d4dd", -- 14 bright cyan (FG only — dirs should use this, not bg)
      "#ffffff", -- 15
    },
    tab_bar = {
      background = "#000000",
      active_tab = {
        bg_color = theme.purple,
        fg_color = "#000000",
        intensity = "Bold",
      },
      -- Slightly lifted from pure black so inactive tabs don't melt into each other
      inactive_tab = {
        bg_color = "#1a1b26",
        fg_color = theme.muted,
      },
      inactive_tab_hover = {
        bg_color = theme.selection,
        fg_color = theme.fg,
      },
      new_tab = {
        bg_color = "#000000",
        fg_color = theme.blue,
      },
      new_tab_hover = {
        bg_color = theme.selection,
        fg_color = theme.fg,
      },
    },
  }
end

local function window_frame_for(theme)
  return {
    font = wezterm.font({ family = "JetBrainsMono Nerd Font Mono", weight = "Medium" }),
    font_size = 10.0,
    active_titlebar_bg = theme.bg_deep,
    inactive_titlebar_bg = theme.bg_deep,
    active_titlebar_fg = theme.fg,
    inactive_titlebar_fg = theme.muted,
    button_fg = theme.fg,
    button_bg = theme.bg_deep,
    button_hover_fg = "#000000",
    button_hover_bg = theme.purple,
  }
end

local function basename(path)
  if not path or path == "" then
    return ""
  end
  path = tostring(path):gsub("^file://", ""):gsub("%%20", " ")
  path = path:gsub("/+$", ""):gsub("\\+$", "")
  return path:match("([^/\\]+)$") or path
end

local function current_dir(pane)
  local cwd = pane:get_current_working_dir()
  if not cwd then
    return ""
  end
  return basename(cwd.file_path or tostring(cwd))
end

local function current_path(pane)
  local cwd = pane:get_current_working_dir()
  if not cwd then
    return ""
  end

  local path = cwd.file_path or tostring(cwd)
  path = tostring(path):gsub("^file://", ""):gsub("%%20", " ")
  return path
end

local function process_name(pane)
  return basename(pane:get_foreground_process_name() or "")
end

local git_cache = {}

local function git_branch_for_path(path)
  if not path or path == "" then
    return ""
  end

  local now = os.time()
  local cached = git_cache[path]
  if cached and now - cached.time < 5 then
    return cached.value
  end

  local ok, stdout = wezterm.run_child_process({
    "git",
    "-C",
    path,
    "symbolic-ref",
    "--quiet",
    "--short",
    "HEAD",
  })

  local branch = ""
  if ok then
    branch = stdout:gsub("%s+$", "")
  else
    local detached_ok, detached_stdout = wezterm.run_child_process({
      "git",
      "-C",
      path,
      "rev-parse",
      "--short",
      "HEAD",
    })
    if detached_ok then
      branch = detached_stdout:gsub("%s+$", "")
    end
  end

  git_cache[path] = {
    time = now,
    value = branch,
  }
  return branch
end

config.automatically_reload_config = true
config.check_for_updates = false
config.default_prog = default_shell
config.default_cwd = work_root
config.default_workspace = "work"
config.window_close_confirmation = "AlwaysPrompt"
config.exit_behavior = "CloseOnCleanExit"
config.color_scheme = active_theme().scheme
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"
config.freetype_load_flags = "NO_HINTING"
config.freetype_load_target = "Light"
config.freetype_render_target = "Normal"

-- Inline images in the terminal:
--   iTerm2 protocol  →  wezterm imgcat path\to\image.png
--   Kitty graphics   →  tools that speak the Kitty image protocol (chafa, etc.)
-- Sixel is experimental and limited on Windows; Kitty/iTerm cover most free tools.
config.enable_kitty_graphics = true

-- Installed on this machine: JetBrainsMono Nerd Font (Mono)
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font Mono", weight = "Regular" },
  { family = "JetBrainsMono Nerd Font", weight = "Regular" },
  { family = "JetBrains Mono", weight = "Regular" },
  "Cascadia Code",
  "Cascadia Mono",
  "Segoe UI Emoji",
})
-- Slightly larger + more line spacing: biggest free win for outdoor + low-brightness reading
config.font_size = 13.0
config.line_height = 1.22
config.cell_width = 1.0
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.warn_about_missing_glyphs = false
config.unicode_version = 14
config.bold_brightens_ansi_colors = true

config.window_padding = {
  left = 14,
  right = 14,
  top = 10,
  bottom = 10,
}
-- Fully opaque pure black only — transparency/Acrylic keeps pixels lit (worse battery on OLED)
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.win32_system_backdrop = "Disable"
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.initial_cols = 132
config.initial_rows = 36
config.adjust_window_size_when_changing_font_size = false
config.max_fps = 120
config.animation_fps = 60
-- Inactive panes: keep readable at low system brightness (was too dim)
config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.78,
}
config.window_frame = window_frame_for(active_theme())

config.command_palette_font_size = 13.0
config.command_palette_bg_color = "#000000"
config.command_palette_fg_color = active_theme().fg

config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_function = "EaseIn",
  fade_in_duration_ms = 80,
  fade_out_function = "EaseOut",
  fade_out_duration_ms = 120,
}

config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBar"
config.force_reverse_video_cursor = false

config.scrollback_lines = 50000
config.enable_scroll_bar = false
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = true
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 28
config.switch_to_last_active_tab_when_closing_tab = true
config.pane_focus_follows_mouse = true
config.swallow_mouse_click_on_pane_focus = true
-- Better key handling for Windows console apps (fzf, pagers, some TUIs)
config.allow_win32_input_mode = true
-- Status bar refresh (git branch cache still 5s; less frequent UI work)
config.status_update_interval = 2000
-- Windows-friendly paste (CRLF from browser/editor → LF)
config.canonicalize_pasted_newlines = "LineFeed"
config.skip_close_confirmation_for_processes_named = {
  "bash",
  "sh",
  "zsh",
  "fish",
  "tmux",
  "nu",
  "cmd.exe",
  "pwsh.exe",
  "powershell.exe",
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- Also link bare www. URLs and Windows paths lightly via quick-select; hyperlinks stay standard.
config.selection_word_boundary = " \t\n{}[]()\"'`,;:"
config.quick_select_patterns = {
  [[https?://[^\s"'<>]+]],
  [[\b[A-Za-z]:\\[^\s"'<>|]+]],
  [[\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b]],
  [[#[0-9a-fA-F]{6}\b]],
  [[\b[0-9a-fA-F]{7,40}\b]],
  [[\b[A-Z]+-[0-9]+\b]],
}

config.set_environment_variables = {
  TERM_PROGRAM = "WezTerm",
  COLORTERM = "truecolor",
}

-- Ctrl+Space: less clash with PowerShell/readline than Ctrl+a
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

config.launch_menu = {
  {
    label = "PowerShell 7",
    args = default_shell,
  },
  {
    label = "Windows PowerShell",
    args = { "powershell.exe", "-NoLogo" },
  },
  {
    label = "Command Prompt",
    args = { "cmd.exe" },
  },
  {
    label = "WSL",
    args = { "wsl.exe" },
  },
}

config.keys = {
  { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
  { key = "L", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) },
  { key = "S", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  { key = "R", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
  -- Open this config in the default editor / associated app
  {
    key = ",",
    mods = "CTRL|SHIFT",
    action = act.SpawnCommandInNewTab({
      args = { "cmd.exe", "/c", "start", "", home .. "\\.wezterm.lua" },
    }),
  },

  { key = "T", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
  { key = "N", mods = "CTRL|SHIFT", action = act.SpawnWindow },
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "F11", mods = "NONE", action = act.ToggleFullScreen },

  -- Font size (explicit, Windows-friendly)
  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },

  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "p", mods = "LEADER", action = act.PaneSelect },
  { key = "S", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
  { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
  { key = "Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },
  { key = "Enter", mods = "LEADER", action = act.EmitEvent("toggle-zen") },
  { key = "o", mods = "LEADER", action = act.EmitEvent("toggle-opacity") },
  { key = "t", mods = "LEADER", action = act.EmitEvent("cycle-theme") },
  { key = "c", mods = "LEADER", action = act.ClearScrollback("ScrollbackAndViewport") },
  -- Open current pane dir in Explorer / copy path (needs OSC 7 cwd tracking)
  { key = "e", mods = "LEADER", action = act.EmitEvent("open-in-explorer") },
  { key = "y", mods = "LEADER", action = act.EmitEvent("copy-cwd") },
  { key = "g", mods = "LEADER", action = act.EmitEvent("open-lazygit") },
  -- Print shortcut cheatsheet in the shell (`keys` command)
  { key = "?", mods = "LEADER", action = act.SendString("keys\r") },
  { key = "/", mods = "LEADER", action = act.SendString("keys\r") },

  { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

  { key = "LeftArrow", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Left", 4 }) },
  { key = "RightArrow", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Right", 4 }) },
  { key = "UpArrow", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Up", 2 }) },
  { key = "DownArrow", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Down", 2 }) },

  { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "F", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "X", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
  { key = "Q", mods = "CTRL|SHIFT", action = act.QuickSelect },
  { key = "O", mods = "CTRL|SHIFT", action = act.EmitEvent("toggle-opacity") },
  { key = "K", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "ALT",
    action = act.ActivateTab(i - 1),
  })
end

config.key_tables = {
  resize_pane = {
    { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
    { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
    { key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
    { key = "Escape", action = act.PopKeyTable },
    { key = "Enter", action = act.PopKeyTable },
  },
}

config.mouse_bindings = {
  -- Select + copy to Windows clipboard on mouse-up
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.CompleteSelection("Clipboard"),
  },
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
  -- Right-click paste (Windows habit)
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
  {
    event = { Down = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor("SemanticZone"),
  },
}

config.colors = theme_overrides(active_theme())

local function pane_fs_path(pane)
  local cwd = pane:get_current_working_dir()
  if not cwd then
    return nil
  end
  local path = cwd.file_path or tostring(cwd)
  path = tostring(path):gsub("^file:///", ""):gsub("^file://", ""):gsub("%%20", " ")
  -- file:///C:/Users/... → C:/Users/...
  path = path:gsub("^/([A-Za-z]):", "%1:"):gsub("/", "\\")
  return path
end

wezterm.on("open-in-explorer", function(window, pane)
  local path = pane_fs_path(pane)
  if not path or path == "" then
    window:toast_notification("WezTerm", "No cwd yet — press Enter once in the shell", nil, 2500)
    return
  end
  wezterm.run_child_process({ "explorer.exe", path })
end)

wezterm.on("copy-cwd", function(window, pane)
  local path = pane_fs_path(pane)
  if not path or path == "" then
    window:toast_notification("WezTerm", "No cwd yet — press Enter once in the shell", nil, 2500)
    return
  end
  window:copy_to_clipboard(path, "Clipboard")
  window:toast_notification("WezTerm", "Copied: " .. path, nil, 2500)
end)

wezterm.on("open-lazygit", function(window, pane)
  local path = pane_fs_path(pane) or work_root
  window:perform_action(
    act.SpawnCommandInNewTab({
      cwd = path,
      args = { "lazygit" },
    }),
    pane
  )
end)

-- Kept for the keybind, but OLED default stays fully opaque black (battery).
-- Toggle still works if you ever want Acrylic; prefer leaving it opaque on OLED.
wezterm.on("toggle-opacity", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.window_background_opacity or config.window_background_opacity

  if current < 1.0 then
    overrides.window_background_opacity = 1.0
    overrides.text_background_opacity = 1.0
    overrides.win32_system_backdrop = "Disable"
  else
    overrides.window_background_opacity = 0.92
    overrides.text_background_opacity = 1.0
    overrides.win32_system_backdrop = "Acrylic"
  end

  window:set_config_overrides(overrides)
end)

wezterm.on("cycle-theme", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local next_index = (wezterm.GLOBAL.kosif_theme_index % #themes) + 1
  local next_theme = themes[next_index]

  wezterm.GLOBAL.kosif_theme_index = next_index
  save_theme_index(next_index)
  overrides.color_scheme = next_theme.scheme
  overrides.colors = theme_overrides(next_theme)
  overrides.window_frame = window_frame_for(next_theme)
  overrides.command_palette_bg_color = "#000000"
  overrides.command_palette_fg_color = next_theme.fg

  window:set_config_overrides(overrides)
  window:toast_notification("WezTerm", "Theme: " .. next_theme.label, nil, 2200)
end)

wezterm.on("toggle-zen", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  if overrides.enable_tab_bar == false then
    overrides.enable_tab_bar = nil
    overrides.window_padding = nil
  else
    overrides.enable_tab_bar = false
    overrides.window_padding = {
      left = 24,
      right = 24,
      top = 18,
      bottom = 16,
    }
  end
  window:set_config_overrides(overrides)
end)

-- Taskbar / Alt-Tab title (Windows Terminal style: useful, short, stable)
wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
  local dir = current_dir(pane)
  local proc = process_name(pane):gsub("%.exe$", ""):gsub("%.EXE$", "")
  local n = #tabs

  -- Prefer folder name; fall back to shell name
  local head = dir
  if head == "" or head == nil then
    head = (proc ~= "" and proc) or "shell"
  end

  -- Zoom hint when a pane is maximized inside the window
  local zoom = ""
  if tab.active_pane and tab.active_pane.is_zoomed then
    zoom = " • zoom"
  end

  if n > 1 then
    return string.format("%s (%d)%s — WezTerm", head, n, zoom)
  end
  return string.format("%s%s — WezTerm", head, zoom)
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local palette = active_theme()
  local pane = tab.active_pane
  local title = current_dir(pane)
  if title == "" then
    title = process_name(pane)
  end
  if title == "" then
    title = "shell"
  end
  -- Windows: "pwsh.exe" → "pwsh"
  title = title:gsub("%.exe$", ""):gsub("%.EXE$", "")

  local zoom = pane.is_zoomed and "·Z" or ""
  local index = tab.tab_index + 1
  -- Leave room for index + padding + inter-tab gap
  title = wezterm.truncate_right(title, math.max(4, max_width - 8))

  -- Gap bar is pure black; tab chips have their own fill so they don't fuse.
  local gap = "#000000"
  local bg = "#1a1b26"
  local fg = palette.muted
  if tab.is_active then
    bg = palette.purple
    fg = "#000000"
  elseif hover then
    bg = palette.selection
    fg = palette.fg
  end

  return {
    { Background = { Color = gap } },
    { Foreground = { Color = gap } },
    { Text = "  " },
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
    { Text = string.format(" %d %s%s ", index, title, zoom) },
    { Background = { Color = gap } },
    { Foreground = { Color = gap } },
    { Text = " " },
  }
end)

wezterm.on("update-right-status", function(window, pane)
  local palette = active_theme()
  local cwd = current_dir(pane)
  local git_branch = git_branch_for_path(current_path(pane))
  local leader = window:leader_is_active() and " LEADER " or ""

  window:set_left_status(wezterm.format({
    { Foreground = { Color = palette.yellow } },
    { Text = leader },
  }))

  local status = {}
  if cwd ~= "" then
    table.insert(status, { Foreground = { Color = palette.cyan } })
    table.insert(status, { Text = cwd })
  end
  if git_branch ~= "" then
    if #status > 0 then
      table.insert(status, { Foreground = { Color = palette.dim } })
      table.insert(status, { Text = "  |  " })
    end
    table.insert(status, { Foreground = { Color = palette.purple } })
    table.insert(status, { Text = git_branch })
  end
  if #status > 0 then
    table.insert(status, { Foreground = { Color = palette.dim } })
    table.insert(status, { Text = "  |  " })
  end
  table.insert(status, { Foreground = { Color = palette.yellow } })
  table.insert(status, { Text = wezterm.strftime("%H:%M ") })

  window:set_right_status(wezterm.format(status))
end)

return config
