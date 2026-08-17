-- Grok host profile. Loaded only via:
--   wezterm --config-file ~/.wezterm-grok.lua start --always-new-process -- grok.exe
-- Separate GUI process so keys/Kitty keyboard never leak into the CLI WezTerm.

local wezterm = require("wezterm")
local act = wezterm.action

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
local work_root = home .. "\\work"
local grok_exe = home .. "\\.grok\\bin\\grok.exe"

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

local theme = {
  fg = "#e8e6f0",
  muted = "#b7a8d4",
  dim = "#8f82ab",
  yellow = "#f1fa8c",
  purple = "#d6acff",
  selection = "#3d3f5c",
}

config.automatically_reload_config = true
config.check_for_updates = false
config.default_prog = { grok_exe }
config.default_cwd = file_exists(work_root) and work_root or home
config.window_close_confirmation = "NeverPrompt"
config.exit_behavior = "CloseOnCleanExit"
config.skip_close_confirmation_for_processes_named = {
  "grok.exe",
  "grok",
}

config.color_scheme = "Dracula (Official)"
config.colors = {
  foreground = theme.fg,
  background = "#000000",
  -- No cursor_* here: Grok sets OSC 12 (theme accent). A fixed WezTerm
  -- cursor color + blink fights that and looks like a stuttering caret.
  selection_bg = theme.selection,
  selection_fg = theme.fg,
  split = theme.dim,
  tab_bar = {
    background = "#000000",
    active_tab = {
      bg_color = theme.purple,
      fg_color = "#000000",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#1a1b26",
      fg_color = theme.muted,
    },
  },
}

config.front_end = "OpenGL"
config.max_fps = 60
config.animation_fps = 60

-- Grok's Ctrl+Enter / Shift+Enter / Ctrl+. need this advertised from process start.
config.enable_kitty_keyboard = true
config.enable_kitty_graphics = true
-- Win32 console input fights Kitty keyboard on this WezTerm build.
config.allow_win32_input_mode = false

config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono NFM", weight = "Regular" },
  { family = "JetBrainsMono Nerd Font Mono", weight = "Regular" },
  { family = "JetBrainsMono NF", weight = "Regular" },
  "Cascadia Mono",
  "Segoe UI Emoji",
})
config.font_size = 13.0
config.line_height = 1.1
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.warn_about_missing_glyphs = false
config.bold_brightens_ansi_colors = true

config.window_padding = {
  left = 6,
  right = 6,
  top = 4,
  bottom = 4,
}
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.win32_system_backdrop = "Disable"
-- Native caption buttons. INTEGRATED_BUTTONS leak clicks on this Windows build.
config.window_decorations = "TITLE|RESIZE"
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = true
config.show_tab_index_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

config.initial_cols = 140
config.initial_rows = 40
config.adjust_window_size_when_changing_font_size = false

config.audible_bell = "Disabled"
-- Grok draws / drives the caret. WezTerm blink on top double-paints.
config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBlock"
config.scrollback_lines = 5000
config.enable_scroll_bar = false
config.pane_focus_follows_mouse = false
config.swallow_mouse_click_on_pane_focus = false
config.canonicalize_pasted_newlines = "LineFeed"

-- Left Alt = modifier (Grok Alt+V image paste). Right Alt = AltGr (Turkish).
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

config.set_environment_variables = {
  TERM_PROGRAM = "WezTerm",
  COLORTERM = "truecolor",
  WEZTERM_GROK_PROFILE = "1",
}

-- Strip WezTerm defaults so Ctrl+N / Ctrl+V / Ctrl+Enter reach Grok.
-- Only keep host utilities (copy, font, fullscreen, emergency paste).
config.disable_default_key_bindings = true

-- Ctrl+C: copy only when WezTerm has a selection; otherwise cancel goes to Grok.
local copy_or_interrupt = wezterm.action_callback(function(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if sel and sel ~= "" then
    window:perform_action(act.CopyTo("Clipboard"), pane)
    window:perform_action(act.ClearSelection, pane)
  else
    window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
  end
end)

config.keys = {
  { key = "c", mods = "CTRL", action = copy_or_interrupt },
  { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },
  { key = "F11", mods = "NONE", action = act.ToggleFullScreen },
  { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
  { key = "T", mods = "CTRL|SHIFT", action = act.EmitEvent("new-grok-tab") },
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "ALT",
    action = act.ActivateTab(i - 1),
  })
end

-- No custom mouse: Grok owns click / scroll / drag-drop. No right-click paste.

local function pane_cwd(pane)
  if not pane then
    return work_root
  end
  local ok, cwd = pcall(function()
    return pane:get_current_working_dir()
  end)
  if not ok or not cwd then
    cwd = pane.current_working_dir
  end
  if not cwd then
    return work_root
  end
  local path = cwd.file_path or tostring(cwd)
  path = tostring(path):gsub("^file:///", ""):gsub("^file://", ""):gsub("%%20", " ")
  path = path:gsub("^/([A-Za-z]):", "%1:"):gsub("/", "\\")
  if path == "" or path == "nil" then
    return work_root
  end
  return path
end

wezterm.on("new-grok-tab", function(window, pane)
  window:perform_action(
    act.SpawnCommandInNewTab({
      cwd = pane_cwd(pane),
      args = { grok_exe },
    }),
    pane
  )
end)

wezterm.on("format-window-title", function(tab, pane, tabs, panes, cfg)
  local info = pane or (tab and tab.active_pane)
  local dir = ""
  if info and info.current_working_dir then
    local path = info.current_working_dir.file_path or tostring(info.current_working_dir)
    path = tostring(path):gsub("/+$", ""):gsub("\\+$", "")
    dir = path:match("([^/\\]+)$") or ""
  end
  if dir ~= "" then
    return string.format("Grok — %s", dir)
  end
  return "Grok"
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local pane = tab.active_pane
  local title = "Grok"
  if pane and pane.current_working_dir then
    local path = pane.current_working_dir.file_path or tostring(pane.current_working_dir)
    path = tostring(path):gsub("/+$", ""):gsub("\\+$", "")
    local dir = path:match("([^/\\]+)$")
    if dir and dir ~= "" then
      title = dir
    end
  end
  title = wezterm.truncate_right(title, math.max(4, (max_width or 24) - 6))
  return {
    { Text = string.format(" %d %s ", tab.tab_index + 1, title) },
  }
end)

return config
