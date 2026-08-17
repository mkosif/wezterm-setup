-- WezTerm: normal terminal first. Grok runs when YOU type `grok`.
-- Tuned for Windows + OLED + Grok TUI (keys not stolen, kitty protocol).
local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder and wezterm.config_builder() or {}

local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
local work_root = home .. "\\work"
local is_windows = wezterm.target_triple:find("windows") ~= nil

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
  local pf = os.getenv("ProgramFiles")
  local pf64 = os.getenv("ProgramW6432")
  local candidates = {
    pf and (pf .. "\\PowerShell\\7\\pwsh.exe"),
    pf64 and (pf64 .. "\\PowerShell\\7\\pwsh.exe"),
    "C:\\Program Files\\PowerShell\\7\\pwsh.exe",
    home .. "\\scoop\\apps\\pwsh\\current\\pwsh.exe",
  }
  for _, p in ipairs(candidates) do
    if file_exists(p) then
      return p
    end
  end
  return "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
end

-- Shell only. No grok.exe here.
local pwsh = is_windows and resolve_pwsh() or "pwsh"
local pwsh_init = home .. "\\config\\wezterm-pwsh.ps1"
local default_shell = is_windows
    and {
      pwsh,
      "-NoLogo",
      "-NoExit",
      "-Command",
      (". '" .. pwsh_init:gsub("'", "''") .. "'"),
    }
  or { os.getenv("SHELL") or "sh", "-l" }

-- Single OLED theme (no cycle, no state file).
local theme = {
  fg = "#e8e6f0",
  muted = "#b7a8d4",
  dim = "#8f82ab",
  blue = "#8be9fd",
  purple = "#d6acff",
  yellow = "#f1fa8c",
  cyan = "#80ffea",
  selection = "#3d3f5c",
}

config.automatically_reload_config = true
config.check_for_updates = false

-- ========== normal terminal startup ==========
config.default_prog = default_shell
config.default_cwd = file_exists(work_root) and work_root or home
-- No gui-startup override. First window = default_prog (pwsh).

config.window_close_confirmation = "NeverPrompt"
config.exit_behavior = "CloseOnCleanExit"

-- 20240203 OpenGL on Windows often hits Mesa/ANGLE: janky scroll, shaky caret.
-- 880M + WebGpu HighPerformance is DX12; LowPower was the old flicker path.
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120
config.animation_fps = 120

-- Grok / modern TUI
config.enable_kitty_graphics = true
config.enable_kitty_keyboard = true
config.allow_win32_input_mode = false
-- Windows IME composition makes the WezTerm caret jitter; Turkish does not need it.
config.use_ime = false

config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono NFM", weight = "Regular" },
  { family = "JetBrainsMono Nerd Font Mono", weight = "Regular" },
  { family = "JetBrainsMono NF", weight = "Regular" },
  "Cascadia Mono",
  "Segoe UI Emoji",
})
config.font_size = 13.0
config.line_height = 1.12
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.warn_about_missing_glyphs = false
config.bold_brightens_ansi_colors = true

config.window_padding = { left = 10, right = 10, top = 8, bottom = 8 }
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.win32_system_backdrop = "Disable"
config.window_decorations = "TITLE|RESIZE"
config.initial_cols = 120
config.initial_rows = 34
config.adjust_window_size_when_changing_font_size = false

-- Tabs: one row, hide when alone
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = true
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 28
config.switch_to_last_active_tab_when_closing_tab = true

config.window_frame = {
  font = wezterm.font({ family = "JetBrainsMono NFM", weight = "Medium" }),
  font_size = 10.0,
  active_titlebar_bg = "#000000",
  inactive_titlebar_bg = "#000000",
  active_titlebar_fg = theme.fg,
  inactive_titlebar_fg = theme.muted,
  button_fg = theme.fg,
  button_bg = "#000000",
  button_hover_fg = "#000000",
  button_hover_bg = theme.purple,
}

config.cursor_blink_rate = 0
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.default_cursor_style = "SteadyBlock"
config.force_reverse_video_cursor = false
config.audible_bell = "Disabled"

config.scrollback_lines = 50000
config.enable_scroll_bar = false
config.pane_focus_follows_mouse = false
config.status_update_interval = 2000
config.canonicalize_pasted_newlines = "LineFeed"
config.skip_close_confirmation_for_processes_named = {
  "bash", "sh", "zsh", "fish", "tmux", "nu",
  "cmd.exe", "pwsh.exe", "powershell.exe",
  "grok.exe", "grok",
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()
config.selection_word_boundary = " \t\n{}[]()\"'`,;:"

config.set_environment_variables = {
  TERM_PROGRAM = "WezTerm",
  COLORTERM = "truecolor",
}

config.color_scheme = "Dracula (Official)"
config.colors = {
  foreground = theme.fg,
  background = "#000000",
  selection_bg = theme.selection,
  selection_fg = theme.fg,
  split = theme.dim,
  ansi = {
    "#000000", "#e84a5f", "#3dd68c", "#d4b84a",
    "#1f6feb", "#a371f7", "#1a7f8c", theme.fg,
  },
  brights = {
    theme.dim, "#ff7b8a", "#56f0a0", "#f0d66a",
    "#79c0ff", "#d2a8ff", "#56d4dd", "#ffffff",
  },
  tab_bar = {
    background = "#000000",
    active_tab = { bg_color = theme.purple, fg_color = "#000000", intensity = "Bold" },
    inactive_tab = { bg_color = "#1a1b26", fg_color = theme.muted },
    inactive_tab_hover = { bg_color = theme.selection, fg_color = theme.fg },
    new_tab = { bg_color = "#000000", fg_color = theme.blue },
    new_tab_hover = { bg_color = theme.selection, fg_color = theme.fg },
  },
}

config.command_palette_font_size = 13.0
config.command_palette_bg_color = "#000000"
config.command_palette_fg_color = theme.fg

-- Launch menu: shells only (no "open as Grok profile")
config.launch_menu = {
  { label = "PowerShell 7", args = default_shell },
  { label = "Windows PowerShell", args = { "powershell.exe", "-NoLogo" } },
  { label = "Command Prompt", args = { "cmd.exe" } },
  { label = "WSL", args = { "wsl.exe" } },
}

-- Ctrl+C: copy if selection, else interrupt
local copy_or_interrupt = wezterm.action_callback(function(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if sel and sel ~= "" then
    window:perform_action(act.CopyTo("Clipboard"), pane)
    window:perform_action(act.ClearSelection, pane)
  else
    window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
  end
end)

-- Minimal keys. Do NOT steal Grok chords (Ctrl+Enter, Ctrl+V, Ctrl+P, …).
config.keys = {
  { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
  { key = "L", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) },
  { key = "R", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
  {
    key = ",",
    mods = "CTRL|SHIFT",
    action = act.SpawnCommandInNewTab({
      args = { "cmd.exe", "/c", "start", "", home .. "\\.wezterm.lua" },
    }),
  },

  { key = "T", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "N", mods = "CTRL|SHIFT", action = act.SpawnWindow },
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "F11", mods = "NONE", action = act.ToggleFullScreen },

  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },

  -- App gets plain Ctrl+V (Grok image paste). Host paste = Ctrl+Shift+V.
  { key = "c", mods = "CTRL", action = copy_or_interrupt },
  { key = "v", mods = "CTRL", action = act.DisableDefaultAssignment },
  { key = "Enter", mods = "CTRL", action = act.DisableDefaultAssignment },
  { key = "Enter", mods = "SHIFT", action = act.DisableDefaultAssignment },
  { key = "Enter", mods = "ALT", action = act.DisableDefaultAssignment },
  { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "F", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "X", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
  { key = "Q", mods = "CTRL|SHIFT", action = act.QuickSelect },
  { key = "K", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },

  -- Splits (no leader complexity)
  { key = "d", mods = "ALT|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
  { key = "z", mods = "ALT|SHIFT", action = act.TogglePaneZoomState },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "ALT",
    action = act.ActivateTab(i - 1),
  })
end

config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
}

local function basename(path)
  if not path or path == "" then
    return ""
  end
  path = tostring(path):gsub("^file://", ""):gsub("%%20", " ")
  path = path:gsub("/+$", ""):gsub("\\+$", "")
  return path:match("([^/\\]+)$") or path
end

local function tab_label(info)
  if not info then
    return "shell"
  end
  local cwd = info.current_working_dir
  if cwd then
    local p = cwd.file_path or tostring(cwd)
    local name = basename(p)
    if name ~= "" then
      return name
    end
  end
  local proc = basename(info.foreground_process_name or "")
  proc = proc:gsub("%.exe$", ""):gsub("%.EXE$", "")
  if proc ~= "" then
    return proc
  end
  return "shell"
end

wezterm.on("format-window-title", function(tab, pane, tabs)
  local info = pane or (tab and tab.active_pane)
  local head = tab_label(info)
  local n = tabs and #tabs or 1
  if n > 1 then
    return string.format("%s (%d) — WezTerm", head, n)
  end
  return string.format("%s — WezTerm", head)
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local title = tab_label(tab.active_pane)
  title = wezterm.truncate_right(title, math.max(4, (max_width or 28) - 4))
  local intensity = tab.is_active and "Bold" or "Normal"
  return {
    { Attribute = { Intensity = intensity } },
    { Text = string.format(" %d %s ", tab.tab_index + 1, title) },
  }
end)

wezterm.on("update-right-status", function(window, pane)
  local cwd = ""
  if pane then
    local ok, dir = pcall(function()
      return pane:get_current_working_dir()
    end)
    if ok and dir then
      cwd = basename(dir.file_path or tostring(dir))
    end
  end
  local bits = {}
  if cwd ~= "" then
    table.insert(bits, { Foreground = { Color = theme.cyan } })
    table.insert(bits, { Text = cwd .. "  " })
  end
  table.insert(bits, { Foreground = { Color = theme.yellow } })
  table.insert(bits, { Text = wezterm.strftime("%H:%M ") })
  window:set_right_status(wezterm.format(bits))
end)

return config
