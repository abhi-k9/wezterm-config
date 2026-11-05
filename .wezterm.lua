local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()
local is_windows = wezterm.target_triple:find('windows') ~= nil
local is_macos = wezterm.target_triple:find('apple') ~= nil

-- Shared settings for Linux, Windows, and macOS.
-- Edit these values directly, or override them in wezterm.local.lua beside
-- this file. That optional file is ignored by Git and is applied LAST.
-- Reference: https://wezterm.org/config/files.html

-- Fonts --------------------------------------------------------------------
-- JetBrains Mono is bundled with WezTerm. Emoji and Nerd Font symbols use
-- WezTerm's fallback fonts; installing a patched primary font is optional.
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 14.0 -- Points, not pixels; each platform scales for its DPI.
config.line_height = 1.0 -- Multiplier: 1.1 adds vertical breathing room.
config.cell_width = 1.0 -- Multiplier: change carefully; wide cells affect alignment.

-- Uncomment to disable programming ligatures (such as != and ->).
-- This changes font shaping, not the underlying text copied to the clipboard.
-- config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- Colors and rendering -----------------------------------------------------
-- Built-in theme; try 'Catppuccin Mocha', 'Catppuccin Latte', or another name
-- from https://wezterm.org/colorschemes/index.html. The leader badge below
-- reads the selected scheme's tab colors instead of maintaining a second palette.
config.color_scheme = 'Catppuccin Macchiato'
config.window_background_opacity = 0.95 -- 0 = transparent, 1 = opaque.
-- Transparency needs compositor support. Text remains opaque; background blur
-- is a separate OS feature. Do not force a renderer (OpenGL/WebGpu) globally:
-- leaving front_end unset lets WezTerm use its default across different GPUs.

-- Frame-rate ceilings, not a demand to redraw an idle terminal constantly.
-- Increase to 120/144/240 on a high-refresh display if the extra work is useful.
config.max_fps = 60
config.animation_fps = 60

-- Unfocused splits are slightly dimmer; these are multipliers, not colors.
-- Set both to 1.0 if all panes should have the same appearance.
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }

-- macOS-only effects are guarded so the shared config stays portable.
if is_macos then
  config.macos_window_background_blur = 0 -- Blur radius; 0 disables blur.
  -- Optional: make the left Option key send Alt sequences to terminal apps.
  -- This also changes how accented/special characters are entered on macOS.
  -- config.send_composed_key_when_left_alt_is_pressed = false
end

-- Window -------------------------------------------------------------------
-- Native controls make dragging, resizing, and closing predictable on each OS.
-- 'RESIZE' alone hides the title bar for a minimal look; window managers may
-- handle decorations differently. FULLSCREEN behavior is OS-controlled.
config.window_decorations = 'TITLE|RESIZE'
config.initial_cols = 120 -- Initial size of a new window in terminal cells.
config.initial_rows = 32 -- Existing windows are not resized on config reload.
config.window_padding = { left = 10, right = 10, top = 8, bottom = 8 } -- Pixels.

-- false keeps the outer window size when changing font size, so the number of
-- rows/columns changes instead. true tries to preserve the terminal grid.
config.adjust_window_size_when_changing_font_size = false
config.hide_mouse_cursor_when_typing = true

-- Optional colored frame. Units can be pixels, points, or fractions of a cell.
-- Uncomment if your platform/window manager supports client-side borders.
-- config.window_frame = {
--   border_left_width = '0.4cell', border_right_width = '0.4cell',
--   border_top_height = '0.15cell', border_bottom_height = '0.15cell',
--   border_left_color = '#b7bdf8', border_right_color = '#b7bdf8',
--   border_top_color = '#b7bdf8', border_bottom_color = '#b7bdf8',
-- }

-- Tabs ---------------------------------------------------------------------
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false -- Retro/cell-based bar; enables our left badge.
config.show_new_tab_button_in_tab_bar = true
config.tab_max_width = 24 -- Maximum title width in cells for the retro tab bar.
config.tab_and_split_indices_are_zero_based = true -- First tab displays as 0.
-- Leader+0 selects the first tab, Leader+1 the second, etc. Built-in tab
-- shortcuts remain available with their usual numbering (e.g. Ctrl+Shift+1
-- selects the first tab). Change the bindings below if you prefer one system.

-- Cursor, scrollback, and bell ----------------------------------------------
config.default_cursor_style = 'SteadyBlock' -- Also: BlinkingBlock/SteadyBar/BlinkingBar.
config.cursor_blink_rate = 500 -- Milliseconds; only relevant for blinking styles.
-- Terminal apps can request their own cursor style, overriding this default.
config.scrollback_lines = 10000 -- History retained per pane; more uses more RAM.
config.scroll_to_bottom_on_input = true -- Typing returns a scrolled pane to the prompt.
config.audible_bell = 'Disabled' -- Silence BEL; enable with 'SystemBeep'.
-- Optional visual alternative (flash the cursor background on BEL):
-- config.visual_bell = { fade_in_duration_ms = 75, fade_out_duration_ms = 150 }

-- Closing ------------------------------------------------------------------
-- Keep a failed process's pane visible so its diagnostic output can be read.
-- Alternatives: 'Close' always closes; 'Hold' always retains the pane.
config.exit_behavior = 'CloseOnCleanExit'
config.window_close_confirmation = 'AlwaysPrompt'
-- WezTerm can still skip prompts for processes it considers safe to close,
-- such as idle shells (skip_close_confirmation_for_processes). Closing a pane
-- through Leader+x requests confirmation; this is not a session backup.

-- Shells and launch menu ---------------------------------------------------
-- Leave default_prog and default_cwd UNSET. WezTerm chooses its platform
-- default shell and new tabs/splits can inherit the active pane's directory.
-- This avoids requiring cmd.exe, PowerShell, bash, or zsh on every machine.
-- To choose a shell locally, set e.g. config.default_prog = { '/bin/zsh', '-l' }
-- in wezterm.local.lua. On Windows an example is { 'pwsh.exe', '-NoLogo' },
-- but PowerShell 7 must be installed before selecting that executable.
config.launch_menu = {}
if is_windows then
  -- Windows-provided choices only. /d avoids cmd's registry AutoRun hooks;
  -- /k keeps it open. These are menu choices, not the default for every OS.
  config.launch_menu = {
    { label = 'Command Prompt', args = { 'cmd.exe', '/d', '/k' } },
    { label = 'Windows PowerShell', args = { 'powershell.exe', '-NoLogo' } },
  }
end
-- Add machine-specific tools to the ignored local file, not this menu.
-- The launcher also lists tabs and workspaces even when this menu is empty.

-- Keyboard -----------------------------------------------------------------
config.disable_default_key_bindings = false -- Keep native shortcuts (including Cmd on macOS).

-- Retained from this layout: Escape is a modal prefix, NOT a normal Escape.
-- Press it, then a binding within 2 seconds. Unbound next keys are swallowed;
-- the timeout does not replay Escape. Press Escape twice to send one Escape
-- to an editor or shell. This can interrupt Vim/readline workflows.
-- Alternative: set key='a', mods='CTRL'; the forwarding binding below adapts.
config.leader = { key = 'Escape', mods = 'NONE', timeout_milliseconds = 2000 }

local function leader_key(key, action, extra_mods)
  return { key = key, mods = 'LEADER' .. (extra_mods and '|' .. extra_mods or ''), action = action }
end

config.keys = {
  -- Double leader forwards the actual configured key and modifiers.
  -- If a local override changes config.leader, it must update this binding too;
  -- the local example shows how to do that without leaving a stale Escape bind.
  leader_key(config.leader.key,
    act.SendKey { key = config.leader.key, mods = config.leader.mods },
    config.leader.mods ~= 'NONE' and config.leader.mods or nil),
  leader_key('c', act.SpawnTab 'CurrentPaneDomain'),
  leader_key('x', act.CloseCurrentPane { confirm = true }),
  leader_key('b', act.ActivateTabRelative(-1)),
  leader_key('n', act.ActivateTabRelative(1)),
  -- Horizontal splits produce side-by-side panes; vertical splits stack panes.
  -- The | key normally requires Shift; this modifier matches the official example.
  leader_key('|', act.SplitHorizontal { domain = 'CurrentPaneDomain' }, 'SHIFT'),
  leader_key('-', act.SplitVertical { domain = 'CurrentPaneDomain' }),
  leader_key('h', act.ActivatePaneDirection 'Left'),
  leader_key('j', act.ActivatePaneDirection 'Down'),
  leader_key('k', act.ActivatePaneDirection 'Up'),
  leader_key('l', act.ActivatePaneDirection 'Right'),
  -- Each resize consumes leader mode; repeat the prefix for another 5 cells.
  leader_key('LeftArrow', act.AdjustPaneSize { 'Left', 5 }),
  leader_key('RightArrow', act.AdjustPaneSize { 'Right', 5 }),
  leader_key('DownArrow', act.AdjustPaneSize { 'Down', 5 }),
  leader_key('UpArrow', act.AdjustPaneSize { 'Up', 5 }),
  leader_key('z', act.TogglePaneZoomState),
  leader_key('f', act.PaneSelect),
  leader_key('p', act.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS|TABS|WORKSPACES' }),
  leader_key('w', act.ShowLauncherArgs { flags = 'WORKSPACES' }),
  leader_key('r', act.ReloadConfiguration),
  leader_key('s', act.Search 'CurrentSelectionOrEmptyString'),
  leader_key('[', act.ActivateCopyMode),
  leader_key('?', act.ActivateCommandPalette, 'SHIFT'),

  -- Explicit portable shortcuts; native defaults remain enabled as well.
  { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
  { key = 'F', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
  { key = 'R', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  { key = '=', mods = 'CTRL|SHIFT', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL|SHIFT', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL|SHIFT', action = act.ResetFontSize },
}

for index = 0, 9 do
  table.insert(config.keys, leader_key(tostring(index), act.ActivateTab(index)))
end

-- Leader indicator ---------------------------------------------------------
-- A small badge in the left of the retro tab bar. Use plain text instead of
-- the wave if your emoji rendering differs between platforms.
local leader_badge = ' 🌊 LEADER '
wezterm.on('update-status', function(window)
  if not window:leader_is_active() then
    window:set_left_status('')
    return
  end
  -- Read the effective palette so theme changes and local color overrides are
  -- reflected after reload. No private process titles/paths are shown here.
  local palette = window:effective_config().resolved_palette
  -- Some built-in/custom themes have no tab_bar section. In that case use an
  -- inverted foreground/background from the effective terminal palette.
  local active_tab = (palette.tab_bar or {}).active_tab or {}
  window:set_left_status(wezterm.format {
    { Background = { Color = active_tab.bg_color or palette.foreground or '#cad3f5' } },
    { Foreground = { Color = active_tab.fg_color or palette.background or '#24273a' } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = leader_badge },
  })
end)

-- Optional private overrides -----------------------------------------------
-- Fixed filename beside the loaded config, on all platforms. Explicit loadfile
-- avoids accidentally finding an unrelated Lua module on package.path.
-- Absence is fine; unreadable files, syntax errors, and runtime errors are not
-- silently ignored. The local file must return function(config, wezterm).
-- After creating the local file for the first time, manually reload with
-- Ctrl+Shift+r (or Cmd+r on macOS); an absent file may not be watchable yet.
local local_path = wezterm.config_dir .. '/wezterm.local.lua'
wezterm.add_to_config_reload_watch_list(local_path)
local local_file, read_error, read_code = io.open(local_path, 'r')
if local_file then
  local_file:close()
  local chunk, load_error = loadfile(local_path)
  assert(chunk, load_error)
  local apply_local = chunk()
  assert(type(apply_local) == 'function', 'wezterm.local.lua must return function(config, wezterm)')
  apply_local(config, wezterm)
elseif read_code ~= 2 then
  error('Cannot read wezterm.local.lua: ' .. tostring(read_error))
end

return config
