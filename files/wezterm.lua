local wezterm = require("wezterm")
local act = wezterm.action

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local is_windows = wezterm.target_triple:find("windows") ~= nil
local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
local work_root = home .. "\\work"

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

-- Prefer the MSI/winget install. Store/AppX aliases are 0-byte stubs and
-- WezTerm cannot launch them as default_prog.
local function resolve_pwsh()
  local pf = os.getenv("ProgramFiles")
  local pf64 = os.getenv("ProgramW6432")
  local localapp = os.getenv("LOCALAPPDATA")
  local candidates = {
    pf and (pf .. "\\PowerShell\\7\\pwsh.exe"),
    pf64 and (pf64 .. "\\PowerShell\\7\\pwsh.exe"),
    "C:\\Program Files\\PowerShell\\7\\pwsh.exe",
    localapp and (localapp .. "\\PowerShell\\7\\pwsh.exe"),
    home .. "\\scoop\\apps\\pwsh\\current\\pwsh.exe",
  }
  for _, p in ipairs(candidates) do
    if file_exists(p) then
      return p
    end
  end
  return "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
end

local grok_exe = home .. "\\.grok\\bin\\grok.exe"

local pwsh = is_windows and resolve_pwsh() or "pwsh"
-- Documents\PowerShell $PROFILE is blocked by Controlled Folder Access, so
-- WezTerm dotsources ~/config/wezterm-pwsh.ps1 itself. -NoExit keeps the
-- session interactive after the init script returns.
local pwsh_oled = home .. "\\config\\wezterm-pwsh.ps1"
local default_shell = is_windows
    and {
      pwsh,
      "-NoLogo",
      "-NoExit",
      "-Command",
      (". '" .. pwsh_oled:gsub("'", "''") .. "'"),
    }
  or { os.getenv("SHELL") or "sh", "-l" }

-- OLED: chrome stays #000000. ANSI 4/6 stay mid-dark so white-on-blue dirs
-- (PowerShell default) stay readable if FileInfo colors fail to load.
local themes = {
  {
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
  return {
    foreground = theme.fg,
    background = "#000000",
    -- Leave cursor color to the app (Grok OSC 12). A fixed blink fights the TUI.
    selection_bg = theme.selection,
    selection_fg = theme.fg,
    scrollbar_thumb = theme.dim,
    split = theme.dim,
    ansi = {
      "#000000",
      "#e84a5f",
      "#3dd68c",
      "#d4b84a",
      "#1f6feb", -- PS directory background; must stay mid-dark
      "#a371f7",
      "#1a7f8c",
      theme.fg,
    },
    brights = {
      theme.dim,
      "#ff7b8a",
      "#56f0a0",
      "#f0d66a",
      "#79c0ff",
      "#d2a8ff",
      "#56d4dd",
      "#ffffff",
    },
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
    font = wezterm.font({ family = "JetBrainsMono NFM", weight = "Medium" }),
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

local function url_to_win_path(cwd)
  if not cwd then
    return nil
  end
  local path = cwd.file_path or tostring(cwd)
  path = tostring(path):gsub("^file:///", ""):gsub("^file://", ""):gsub("%%20", " ")
  path = path:gsub("^/([A-Za-z]):", "%1:"):gsub("/", "\\")
  if path == "" or path == "nil" then
    return nil
  end
  return path
end

-- format-tab-title / format-window-title receive PaneInformation (fields only).
-- Calling :get_current_working_dir() on those throws and WezTerm falls back to
-- overlapping "pwsh.exe" titles. MuxPane methods exist only in status/events.
local function info_path(info)
  if not info then
    return nil
  end
  return url_to_win_path(info.current_working_dir)
end

local function info_dir(info)
  return basename(info_path(info) or "")
end

local function info_process(info)
  if not info then
    return ""
  end
  return basename(info.foreground_process_name or info.title or ""):gsub("%.exe$", ""):gsub("%.EXE$", "")
end

local function mux_path(pane)
  if not pane then
    return nil
  end
  local ok, cwd = pcall(function()
    return pane:get_current_working_dir()
  end)
  if not ok then
    return url_to_win_path(pane.current_working_dir)
  end
  return url_to_win_path(cwd)
end

local function mux_dir(pane)
  return basename(mux_path(pane) or "")
end

local function mux_process(pane)
  if not pane then
    return ""
  end
  local ok, name = pcall(function()
    return pane:get_foreground_process_name()
  end)
  if not ok or not name then
    name = pane.foreground_process_name
  end
  return basename(name or ""):gsub("%.exe$", ""):gsub("%.EXE$", "")
end

local function tab_label(pane_info)
  local title = info_dir(pane_info)
  if title == "" then
    title = info_process(pane_info)
  end
  if title == "" then
    title = "shell"
  end
  return title
end

config.automatically_reload_config = true
config.check_for_updates = false
config.default_prog = default_shell
config.default_cwd = file_exists(work_root) and work_root or home
config.default_workspace = "work"
config.window_close_confirmation = "NeverPrompt"
config.exit_behavior = "CloseOnCleanExit"
config.color_scheme = active_theme().scheme

-- 20240203 WebGpu+LowPower on Windows: flicker / input lag / rare panics.
-- OpenGL is the stable backend for this build.
config.front_end = "OpenGL"
config.max_fps = 60
config.animation_fps = 60

config.enable_kitty_graphics = true
config.enable_kitty_keyboard = true

config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono NFM", weight = "Regular" },
  { family = "JetBrainsMono Nerd Font Mono", weight = "Regular" },
  { family = "JetBrainsMono NF", weight = "Regular" },
  { family = "JetBrainsMono Nerd Font", weight = "Regular" },
  "Cascadia Mono",
  "Segoe UI Emoji",
})
config.font_size = 13.0
config.line_height = 1.1
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.warn_about_missing_glyphs = false
config.bold_brightens_ansi_colors = true

config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.win32_system_backdrop = "Disable"
-- INTEGRATED_BUTTONS are WezTerm-drawn; on this Windows build clicks leak
-- through to the window underneath. Native caption buttons do not.
config.window_decorations = "TITLE|RESIZE"
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = true
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 32
config.switch_to_last_active_tab_when_closing_tab = true

config.initial_cols = 120
config.initial_rows = 34
config.adjust_window_size_when_changing_font_size = false
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.82,
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

config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBlock"
config.force_reverse_video_cursor = false

config.scrollback_lines = 20000
config.enable_scroll_bar = false
config.pane_focus_follows_mouse = false
config.swallow_mouse_click_on_pane_focus = false
config.allow_win32_input_mode = false
config.status_update_interval = 1000
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
  "grok.exe",
  "grok",
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()
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

-- Ctrl+Space is PSReadLine MenuComplete (Windows mode). Do not steal it.
config.leader = { key = "Space", mods = "CTRL|SHIFT", timeout_milliseconds = 1500 }

config.launch_menu = {
  { label = "Grok", args = { grok_exe } },
  { label = "PowerShell 7", args = default_shell },
  { label = "Windows PowerShell", args = { "powershell.exe", "-NoLogo" } },
  { label = "Command Prompt", args = { "cmd.exe" } },
  { label = "WSL", args = { "wsl.exe" } },
}

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
  -- Default for this combo is QuickSelect; leader needs the key free.
  { key = "Space", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
  { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
  { key = "L", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) },
  { key = "S", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  { key = "R", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
  {
    key = ",",
    mods = "CTRL|SHIFT",
    action = act.SpawnCommandInNewTab({
      args = { "cmd.exe", "/c", "start", "", home .. "\\.wezterm.lua" },
    }),
  },

  -- New tab = shell. First window / Ctrl+Shift+N / Ctrl+Shift+G = Grok.
  { key = "T", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "N", mods = "CTRL|SHIFT", action = act.EmitEvent("open-grok-window") },
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "F11", mods = "NONE", action = act.ToggleFullScreen },

  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },

  -- Ctrl+V stays with the app (Grok image paste / PSReadLine). Shift+V is host paste.
  { key = "c", mods = "CTRL", action = copy_or_interrupt },
  { key = "v", mods = "CTRL", action = act.DisableDefaultAssignment },
  { key = "n", mods = "CTRL", action = act.DisableDefaultAssignment },
  { key = "Enter", mods = "CTRL", action = act.DisableDefaultAssignment },
  { key = "Enter", mods = "SHIFT", action = act.DisableDefaultAssignment },
  { key = "Enter", mods = "ALT", action = act.DisableDefaultAssignment },
  { key = "v", mods = "ALT", action = act.DisableDefaultAssignment },
  { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "F", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "X", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
  { key = "Q", mods = "CTRL|SHIFT", action = act.QuickSelect },
  { key = "O", mods = "CTRL|SHIFT", action = act.EmitEvent("toggle-opacity") },
  { key = "G", mods = "CTRL|SHIFT", action = act.EmitEvent("open-grok") },
  { key = "K", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },
  { key = "d", mods = "ALT|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "p", mods = "LEADER", action = act.PaneSelect },
  { key = "S", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
  { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
  { key = "Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },
  { key = "Enter", mods = "LEADER", action = act.EmitEvent("toggle-zen") },
  { key = "o", mods = "LEADER", action = act.EmitEvent("toggle-opacity") },
  { key = "t", mods = "LEADER", action = act.EmitEvent("cycle-theme") },
  { key = "c", mods = "LEADER", action = act.ClearScrollback("ScrollbackAndViewport") },
  { key = "e", mods = "LEADER", action = act.EmitEvent("open-in-explorer") },
  { key = "y", mods = "LEADER", action = act.EmitEvent("copy-cwd") },
  { key = "g", mods = "LEADER", action = act.EmitEvent("open-lazygit") },
  { key = "G", mods = "LEADER", action = act.EmitEvent("open-grok") },
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

config.colors = theme_overrides(active_theme())

wezterm.on("open-in-explorer", function(window, pane)
  local path = mux_path(pane)
  if not path or path == "" then
    window:toast_notification("WezTerm", "No cwd yet — press Enter once in the shell", nil, 2500)
    return
  end
  wezterm.run_child_process({ "explorer.exe", path })
end)

wezterm.on("copy-cwd", function(window, pane)
  local path = mux_path(pane)
  if not path or path == "" then
    window:toast_notification("WezTerm", "No cwd yet — press Enter once in the shell", nil, 2500)
    return
  end
  window:copy_to_clipboard(path, "Clipboard")
  window:toast_notification("WezTerm", "Copied: " .. path, nil, 2500)
end)

wezterm.on("open-lazygit", function(window, pane)
  local path = mux_path(pane) or work_root
  window:perform_action(
    act.SpawnCommandInNewTab({
      cwd = path,
      args = { "lazygit" },
    }),
    pane
  )
end)

wezterm.on("gui-startup", function(cmd)
  local mux = wezterm.mux
  local cwd = work_root
  if cmd and cmd.cwd and tostring(cmd.cwd) ~= "" then
    cwd = cmd.cwd
  end
  local args
  if cmd and cmd.args and #cmd.args > 0 then
    args = cmd.args
  elseif file_exists(grok_exe) then
    args = { grok_exe }
  else
    args = default_shell
  end
  mux.spawn_window({
    args = args,
    cwd = cwd,
  })
end)

wezterm.on("open-grok", function(window, pane)
  if not file_exists(grok_exe) then
    window:toast_notification("WezTerm", "grok.exe not found at ~/.grok/bin", nil, 3000)
    return
  end
  window:perform_action(
    act.SpawnCommandInNewTab({
      cwd = mux_path(pane) or work_root,
      args = { grok_exe },
    }),
    pane
  )
end)

wezterm.on("open-grok-window", function(window, pane)
  if not file_exists(grok_exe) then
    window:toast_notification("WezTerm", "grok.exe not found at ~/.grok/bin", nil, 3000)
    return
  end
  window:perform_action(
    act.SpawnCommandInNewWindow({
      cwd = mux_path(pane) or work_root,
      args = { grok_exe },
    }),
    pane
  )
end)

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

wezterm.on("format-window-title", function(tab, pane, tabs, panes, cfg)
  local info = pane or (tab and tab.active_pane)
  local head = tab_label(info)
  local zoom = (info and info.is_zoomed) and " • zoom" or ""
  local n = tabs and #tabs or 1
  if n > 1 then
    return string.format("%s (%d)%s — WezTerm", head, n, zoom)
  end
  return string.format("%s%s — WezTerm", head, zoom)
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local pane = tab.active_pane
  local title = tab_label(pane)
  local zoom = (pane and pane.is_zoomed) and " Z" or ""
  local index = tab.tab_index + 1
  local width = max_width or 32
  title = wezterm.truncate_right(title, math.max(4, width - 6))

  local intensity = tab.is_active and "Bold" or "Normal"
  return {
    { Attribute = { Intensity = intensity } },
    { Text = string.format(" %d %s%s ", index, title, zoom) },
  }
end)

-- No git(1) from the GUI process — run_child_process on the status tick
-- froze/crashed 20240203 (stdio panic in the log).
wezterm.on("update-right-status", function(window, pane)
  local palette = active_theme()
  local cwd = mux_dir(pane)
  local leader = window:leader_is_active() and " LEADER " or ""

  window:set_left_status(wezterm.format({
    { Foreground = { Color = palette.yellow } },
    { Text = leader },
  }))

  local status = {}
  if cwd ~= "" then
    table.insert(status, { Foreground = { Color = palette.cyan } })
    table.insert(status, { Text = cwd })
    table.insert(status, { Foreground = { Color = palette.dim } })
    table.insert(status, { Text = "  |  " })
  end
  table.insert(status, { Foreground = { Color = palette.yellow } })
  table.insert(status, { Text = wezterm.strftime("%H:%M ") })

  window:set_right_status(wezterm.format(status))
end)

return config
