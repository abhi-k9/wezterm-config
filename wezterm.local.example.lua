-- Copy to wezterm.local.lua BESIDE the config WezTerm actually loads.
-- The local file is ignored by Git. Keep private paths and profiles there;
-- this example intentionally contains no workstation-specific configuration.
-- Missing local file = shared defaults. A broken local file surfaces an error.
return function(config, wezterm)
  -- Preferences can override any earlier shared setting:
  -- config.font_size = 16
  -- config.window_background_opacity = 1.0
  -- config.color_scheme = 'Catppuccin Mocha'

  -- Optional alternative leader: Ctrl+a. This replaces BOTH the leader and its
  -- double-press forwarding shortcut, so ordinary Escape reaches applications.
  -- The main config's first key entry is the forwarding binding.
  -- config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
  -- config.keys[1] = {
  --   key = 'a', mods = 'LEADER|CTRL',
  --   action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' },
  -- }

  -- Shell override: choose only executables actually installed on THIS machine.
  -- if wezterm.target_triple:find('windows') then
  --   config.default_prog = { 'pwsh.exe', '-NoLogo' } -- Requires PowerShell 7.
  -- elseif wezterm.target_triple:find('apple') then
  --   config.default_prog = { '/bin/zsh', '-l' }
  -- end

  -- Workstation tools: put initialization in a local wrapper script. Checking
  -- for that script keeps its menu entry off machines where it is unavailable.
  -- For dependent setup steps, the wrapper should stop/report on failure instead
  -- of continuing through an incompletely initialized environment.
  -- if wezterm.target_triple:find('windows') then
  --   local script = [[C:\path\to\local-init.cmd]] -- Replace ONLY in the local copy.
  --   local file = io.open(script, 'r')
  --   if file then
  --     file:close()
  --     table.insert(config.launch_menu, {
  --       label = 'Local tools',
  --       args = { 'cmd.exe', '/d', '/k', 'call "' .. script .. '"' },
  --     })
  --   end
  -- end
end
