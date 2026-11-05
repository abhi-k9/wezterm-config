local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()
local is_windows = wezterm.target_triple:find('windows') ~= nil
local is_macos = wezterm.target_triple:find('apple') ~= nil

-- Shared settings for Linux, Windows, and macOS.
-- Edit these values directly, or override them in wezterm.local.lua beside
-- the installed config. The repository's local file is a tracked public
-- example; keep private overrides in the installed copy outside this checkout.
-- That optional local file is applied LAST.
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
-- from https://wezterm.org/colorschemes/index.html. The mode badge below
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
config.use_fancy_tab_bar = false -- Retro bar; keep visible for the APP/WEZ badge.
config.show_new_tab_button_in_tab_bar = true
config.tab_max_width = 24 -- Maximum title width in cells for the retro tab bar.
config.tab_and_split_indices_are_zero_based = true -- First tab displays as 0.
-- In WEZ mode, Ctrl+Shift+Space then 0 selects the first outer tab, 1 the
-- second, etc. Direct Ctrl+Shift+1..8 selects the first eight tabs; 9 the last.
-- These commands address WezTerm tabs, not tabs within Zellij.

-- Cursor, scrollback, and bell ----------------------------------------------
config.default_cursor_style = 'SteadyBlock' -- Also: BlinkingBlock/SteadyBar/BlinkingBar.
config.cursor_blink_rate = 500 -- Milliseconds; only relevant for blinking styles.
-- Terminal apps can request their own cursor style, overriding this default.
config.scrollback_lines = 10000 -- History retained per pane; more uses more RAM.
-- WezTerm hides the scrollbar by default. Show it at the window's right edge;
-- it uses the existing right padding and tracks the active pane's scrollback.
-- Set false locally for a minimal view. In WEZ mode, Shift+PageUp/PageDown
-- scroll this outer history. Use Zellij scroll mode for inner pane history.
config.enable_scroll_bar = true
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
-- such as idle shells (skip_close_confirmation_for_processes_named). Closing a pane
-- via the WEZ command prefix then x requests confirmation. An outer pane
-- close disconnects the entire Zellij client it hosts; use Zellij to close
-- an inner pane. Confirmation is not a session backup.

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
-- Add machine-specific tools to the installed local copy, outside this checkout.
-- The launcher also lists tabs and workspaces even when this menu is empty.

-- Input routing: WezTerm -> Zellij -> Neovim --------------------------------
-- APP is the default in each window and after a config reload. Fullscreen,
-- the mode toggle, and host-clipboard paste are reserved. Other input follows the
-- normal terminal path to the application (subject to OS/terminal encoding).
-- Never set a native config.leader: it is checked BEFORE key tables and would
-- intercept Escape or another prefix even in APP mode.
config.disable_default_key_bindings = true
config.status_update_interval = 200 -- Milliseconds; refresh the small mode badge.

local function key(key_name, mods, action)
  return { key = key_name, mods = mods, action = action }
end

-- A single global event toggles the current GUI window. Named tables fall
-- through to these globals, so fullscreen, the toggle, and paste work in both modes.
-- Clearing the stack also exits a pending command prefix. CopyMode Close is
-- harmless outside the copy/search UI and releases that UI when returning APP.
wezterm.on('toggle-input-mode', function(window, pane)
  if window:active_key_table() then
    window:perform_action(act.Multiple {
      act.CopyMode 'Close',
      act.ClearKeyTableStack,
    }, pane)
  else
    window:perform_action(act.ActivateKeyTable {
      name = 'wezterm', one_shot = false, until_unknown = false,
      prevent_fallback = false,
    }, pane)
  end
end)

config.keys = {
  key('Enter', 'ALT', act.ToggleFullScreen),
  key('F12', 'CTRL|SHIFT', act.EmitEvent 'toggle-input-mode'),
  -- Paste clipboard text into the focused terminal, including a Zellij pane,
  -- without switching modes. Plain Ctrl+v still goes to the application.
  key('V', 'CTRL|SHIFT', act.PasteFrom 'Clipboard'),
}
if is_macos then
  table.insert(config.keys, key('v', 'SUPER', act.PasteFrom 'Clipboard'))
end

-- WEZ enables an explicit outer-terminal keymap. Plain F12 is deliberately
-- absent: it reaches Zellij in both modes. Ordinary Escape is also unbound.
-- Unmatched keys fall through to the application; WEZ is not a typing lock.
local wez_keys = {
  -- A literal space selects the mapped space character. The name 'Space'
  -- resolves to a physical key in some builds/backends and can miss events.
  key(' ', 'CTRL|SHIFT', act.ActivateKeyTable {
    -- one_shot also ends on an unmatched non-modifier. Keep until_unknown
    -- false so pressing Shift for | or ? does not cancel the command table.
    name = 'wezterm_commands', one_shot = true, until_unknown = false,
    timeout_milliseconds = 2000, prevent_fallback = false,
  }),
  key('C', 'CTRL|SHIFT', act.CopyTo 'Clipboard'),
  key('F', 'CTRL|SHIFT', act.Search 'CurrentSelectionOrEmptyString'),
  key('P', 'CTRL|SHIFT', act.ActivateCommandPalette),
  key('R', 'CTRL|SHIFT', act.ReloadConfiguration),
  key('L', 'CTRL|SHIFT', act.ShowDebugOverlay),
  -- Physical positions keep Shift+number/symbol chords from becoming !/)/_
  -- before matching. Labels refer to the usual number row and +/- positions.
  key('phys:Equal', 'CTRL|SHIFT', act.IncreaseFontSize),
  key('phys:Minus', 'CTRL|SHIFT', act.DecreaseFontSize),
  key('phys:0', 'CTRL|SHIFT', act.ResetFontSize),
  key('T', 'CTRL|SHIFT', act.SpawnTab 'CurrentPaneDomain'),
  key('N', 'CTRL|SHIFT', act.SpawnWindow),
  key('W', 'CTRL|SHIFT', act.CloseCurrentTab { confirm = true }),
  key('Tab', 'CTRL', act.ActivateTabRelative(1)),
  key('Tab', 'CTRL|SHIFT', act.ActivateTabRelative(-1)),
  key('PageUp', 'SHIFT', act.ScrollByPage(-1)),
  key('PageDown', 'SHIFT', act.ScrollByPage(1)),
}
for index = 1, 9 do
  table.insert(wez_keys, key('phys:' .. tostring(index), 'CTRL|SHIFT',
    act.ActivateTab(index == 9 and -1 or index - 1)))
end

-- Other macOS Cmd equivalents are explicit WEZ-only bindings. Cmd+v is global
-- above; OS-owned shortcuts/menu actions remain OS-controlled.
if is_macos then
  for _, binding in ipairs {
    key('c', 'SUPER', act.CopyTo 'Clipboard'),
    key('f', 'SUPER', act.Search 'CurrentSelectionOrEmptyString'),
    key('p', 'SUPER|SHIFT', act.ActivateCommandPalette),
    key('r', 'SUPER', act.ReloadConfiguration),
    key('phys:Equal', 'SUPER', act.IncreaseFontSize),
    key('phys:Equal', 'SUPER|SHIFT', act.IncreaseFontSize),
    key('phys:Minus', 'SUPER', act.DecreaseFontSize),
    key('phys:0', 'SUPER', act.ResetFontSize),
    key('t', 'SUPER', act.SpawnTab 'CurrentPaneDomain'),
    key('n', 'SUPER', act.SpawnWindow),
    key('w', 'SUPER', act.CloseCurrentTab { confirm = true }),
  } do
    table.insert(wez_keys, binding)
  end
  for index = 1, 9 do
    table.insert(wez_keys, key('phys:' .. tostring(index), 'SUPER',
      act.ActivateTab(index == 9 and -1 or index - 1)))
  end
end

-- A one-shot command prefix exists only in WEZ mode. It returns to WEZ after
-- one action or 2 seconds. An unknown key cancels the prefix and follows the
-- normal WEZ routing. Escape cancels it AND sends one literal Escape onward.
-- There is no automatic switch based on a process name or Zellij's lock state.
local commands = {
  key('Escape', 'NONE', act.SendKey { key = 'Escape', mods = 'NONE' }),
  key('c', 'NONE', act.SpawnTab 'CurrentPaneDomain'),
  key('x', 'NONE', act.CloseCurrentPane { confirm = true }),
  key('b', 'NONE', act.ActivateTabRelative(-1)),
  key('n', 'NONE', act.ActivateTabRelative(1)),
  key('|', 'SHIFT', act.SplitHorizontal { domain = 'CurrentPaneDomain' }),
  key('-', 'NONE', act.SplitVertical { domain = 'CurrentPaneDomain' }),
  key('h', 'NONE', act.ActivatePaneDirection 'Left'),
  key('j', 'NONE', act.ActivatePaneDirection 'Down'),
  key('k', 'NONE', act.ActivatePaneDirection 'Up'),
  key('l', 'NONE', act.ActivatePaneDirection 'Right'),
  key('LeftArrow', 'NONE', act.AdjustPaneSize { 'Left', 5 }),
  key('RightArrow', 'NONE', act.AdjustPaneSize { 'Right', 5 }),
  key('DownArrow', 'NONE', act.AdjustPaneSize { 'Down', 5 }),
  key('UpArrow', 'NONE', act.AdjustPaneSize { 'Up', 5 }),
  key('z', 'NONE', act.TogglePaneZoomState),
  key('f', 'NONE', act.PaneSelect),
  key('p', 'NONE', act.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS|TABS|WORKSPACES' }),
  key('w', 'NONE', act.ShowLauncherArgs { flags = 'WORKSPACES' }),
  key('r', 'NONE', act.ReloadConfiguration),
  key('s', 'NONE', act.Search 'CurrentSelectionOrEmptyString'),
  key('[', 'NONE', act.ActivateCopyMode),
  key('?', 'SHIFT', act.ActivateCommandPalette),
}
for index = 0, 9 do
  table.insert(commands, key(tostring(index), 'NONE', act.ActivateTab(index)))
end
config.key_tables = { wezterm = wez_keys, wezterm_commands = commands }

-- Visible per-window input state. Keep the retro tab bar visible to see it.
-- WezTerm's own copy/search/picker UIs can temporarily handle their UI keys;
-- the mode toggle exits copy/search as well as the command stack.
wezterm.on('update-status', function(window)
  local name = window:active_key_table()
  -- active_key_table also reports copy_mode/search_mode while their UI owns
  -- input. Keep the badge WEZ there, instead of misleadingly showing APP.
  local is_wez = name ~= nil
  local badge = is_wez and ' WEZ ' or ' APP '
  if name == 'wezterm_commands' then badge = ' WEZ · CMD ' end
  local palette = window:effective_config().resolved_palette
  local tab = (palette.tab_bar or {}).active_tab or {}
  window:set_left_status(wezterm.format {
    { Background = { Color = is_wez and (tab.bg_color or palette.foreground or '#cad3f5')
      or (palette.background or '#24273a') } },
    { Foreground = { Color = is_wez and (tab.fg_color or palette.background or '#24273a')
      or (palette.foreground or '#cad3f5') } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = badge },
  })
end)

-- Optional private overrides -----------------------------------------------
-- Fixed filename beside the loaded config, on all platforms. Explicit loadfile
-- avoids accidentally finding an unrelated Lua module on package.path.
-- The checkout includes a no-op example under this name. Home installations
-- can use their own private copy or omit it entirely.
-- Absence is fine; unreadable files, syntax errors, and runtime errors are not
-- silently ignored. The local file must return function(config, wezterm).
-- After creating the local file for the first time, enter WEZ with
-- Ctrl+Shift+F12, then reload with Ctrl+Shift+r (Cmd+r on macOS). A new
-- local file may not be watchable until this first manual reload.
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

-- Catch legacy local-template overrides that would silently defeat APP mode.
assert(config.leader == nil,
  'Remove config.leader from wezterm.local.lua; use the WEZ command key table instead')
assert(config.disable_default_key_bindings == true,
  'APP routing requires disable_default_key_bindings = true; add keys to the WEZ table')

return config
