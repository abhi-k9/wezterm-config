# WezTerm configuration

A documented configuration for Linux, Windows, and macOS, with Catppuccin
Macchiato, a bottom tab bar, and leader shortcuts for tabs, panes, and workspaces.

Open [the HTML cheatsheet](cheatsheets/wezterm-cheatsheet.html) in a browser for
keybindings and common workflows. It is self-contained, works offline, adapts
to smaller screens, and has a light print layout.

## Setup

Follow the [setup guide](docs/SETUP.md) for prerequisites, copy-and-paste commands,
backups, private profiles, updates, and troubleshooting:

- [Windows / PowerShell](docs/SETUP.md#windows-powershell)
- [Linux](docs/SETUP.md#linux)
- [macOS](docs/SETUP.md#macos)

The recommended layout keeps the clone in a subfolder and the active config in
your home directory. Cloning alone does not make WezTerm load the checkout.

| File | Windows | Linux / macOS |
| --- | --- | --- |
| Repository | `%USERPROFILE%\wezterm-config\` | `~/wezterm-config/` |
| Active shared config | `%USERPROFILE%\.wezterm.lua` | `~/.wezterm.lua` |
| Optional private profile | `%USERPROFILE%\wezterm.local.lua` | `~/wezterm.local.lua` |

The private profile lives beside the active config. Download it from your own
storage, or use the generic local example; it is not distributed by this
repository. An update copies only `.wezterm.lua`, leaving `wezterm.local.lua`
untouched. The guide also explains how to test the checkout before installation.

## Customize shared settings

The comments in [.wezterm.lua](.wezterm.lua) explain each setting, its units,
tradeoffs, and useful alternatives. The main groups are:

- Font family, point size, spacing, and optional ligatures.
- Theme, transparency, inactive-pane dimming, and rendering frame-rate limits.
- Window controls, padding, initial grid size, and font-resize behavior.
- Tab-bar position, style, title width, and zero-based indices.
- Cursor style, blink interval, scrollback, bell, and close behavior.
- Native shells, platform-specific launch choices, leader keys, and shortcuts.

The shared config leaves `default_prog` unset, allowing WezTerm to choose its
platform default shell. Windows-specific launch choices are created only on
Windows. No optional shell, shell plugin, or external command is required for
normal startup. JetBrains Mono and Nerd Font symbol fallback are bundled with
WezTerm. Transparency and decorations depend on the OS/compositor; use opacity
`1.0` if transparency is unavailable.

## Keep machine-specific profiles local

Copy [wezterm.local.example.lua](wezterm.local.example.lua) to
`wezterm.local.lua` beside the configuration WezTerm actually loads. For example,
if using `~/.wezterm.lua`, the local file belongs at `~/wezterm.local.lua`.
If using a symlink, check the active `wezterm.config_dir` in WezTerm's debug
overlay rather than assuming which directory contains the loaded config.

The local file returns a function and runs after all shared settings:

```lua
return function(config, wezterm)
  config.font_size = 16
  config.window_background_opacity = 1.0
  -- Add local launch_menu entries or default_prog here.
end
```

Workstation-only tools belong in this local layer. The example shows how to
check the platform and the existence of a local initialization script before
adding its launch-menu entry. Put a multi-step setup in that local wrapper;
stop or report failures when later commands depend on earlier steps. The shared
config then remains useful on machines where those tools do not exist.

`.gitignore` excludes the local file and other `wezterm.local.*.lua` profiles,
while retaining the generic example. Check `git status` before committing.
Ignoring a file does not remove a previously tracked file from Git history.

A missing local file is allowed. Read errors, syntax errors, an incorrect return
type, and runtime errors surface instead of silently loading different settings.
After creating the file for the first time, reload with `Ctrl+Shift+r` or `Cmd+r`
on macOS. Existing files are registered for automatic reload on edits.

## Leader and daily use

The default leader is **Escape** with a two-second timeout. Press Escape, release
it, then press the action key. A single Escape is consumed; timing out does not
send it to the application. Double Escape sends one literal Escape. Unmapped
keys after the leader are also consumed.

If that interferes with your editor, the local example includes a complete
`Ctrl+a` alternative. It updates the double-leader forwarding shortcut as well.
Changing the shared leader before the bindings are constructed also updates the
forwarding shortcut automatically. `Ctrl+a` has its own application conflicts;
choose according to your workflow.

| Sequence | Action |
| --- | --- |
| Leader, `c` | New tab |
| Leader, `b` / `n` | Previous / next tab |
| Leader, `0`–`9` | Select zero-based tab index |
| Leader, `Shift+\|` / `-` | Split side by side / above and below |
| Leader, `h` / `j` / `k` / `l` | Focus left / down / up / right |
| Leader, arrow | Resize by five cells; repeat leader for another resize |
| Leader, `f` / `z` / `x` | Pane picker / zoom toggle / close with confirmation |
| Leader, `p` / `w` | Launcher / workspaces |
| Leader, `s` / `[` | Search / copy mode |
| Leader, `r` / `Shift+?` | Reload / command palette |

`Ctrl+Shift+c/v/f/p/r` provide copy, paste, search, command palette, and reload.
`Ctrl+Shift+=/-/0` increase, decrease, and reset the font size. Built-in shortcuts,
including macOS Cmd shortcuts, remain enabled. Built-in tab-number shortcuts
retain their usual numbering, so `Ctrl+Shift+1` selects the first tab while
Leader, `1` selects the second.

Workspaces group live windows/tabs/panes. They are not snapshots of running
programs and do not provide restoration after the multiplexer exits or reboots.

## Checks

This configuration targets WezTerm `20240203-110809-5046fc22` or newer. After a
version change, load it and inspect fonts and bindings:

```sh
wezterm --config-file /path/to/.wezterm.lua show-keys --lua
wezterm --config-file /path/to/.wezterm.lua ls-fonts
python3 -m unittest discover -s tests -v
```

Use `python` instead of `python3` where appropriate. Tests use a WezTerm binary
on PATH, or the executable specified by `WEZTERM_BIN`. They exercise the real
Lua/configuration APIs, platform branches, optional overrides, and error paths.
Platform simulation validates configuration logic; test native shells, key
events, and window effects on each OS as well.
