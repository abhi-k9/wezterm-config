# WezTerm configuration

A documented configuration for Linux, Windows, and macOS, with Catppuccin
Macchiato, a bottom tab bar, and leader shortcuts for tabs, panes, and workspaces.

Open a focused HTML cheatsheet in a browser:

| Sheet | Use it for |
| --- | --- |
| [Keymap](cheatsheets/wezterm-keymap.html) | Look up shortcuts, including closing panes, tabs, and windows. |
| [Workflows](cheatsheets/wezterm-workflows.html) | Follow task recipes for layouts, projects, copying output, and finishing work. |
| [Architecture](cheatsheets/wezterm-architecture.html) | Understand panes, tabs, windows, workspaces, domains, profiles, and process lifetime. |

Each sheet has inline styling, works offline, adapts to smaller screens, and has
a light print layout. Download the companion files together for local navigation.
The [original cheatsheet URL](cheatsheets/wezterm-cheatsheet.html) is now an overview
linking to these separate references.

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

The private profile lives beside the active config. The repository includes a
commented, generic [wezterm.local.lua](wezterm.local.lua); copy it to your home
directory before adding private settings. An update copies only `.wezterm.lua`,
leaving your home-directory `wezterm.local.lua` untouched. The guide also explains
how to test the checkout before installation.

## Customize shared settings

The comments in [.wezterm.lua](.wezterm.lua) explain each setting, its units,
tradeoffs, and useful alternatives. The main groups are:

- Font family, point size, spacing, and optional ligatures.
- Theme, transparency, inactive-pane dimming, and rendering frame-rate limits.
- Window controls, padding, initial grid size, and font-resize behavior.
- Tab-bar position, style, title width, and zero-based indices.
- Cursor style, blink interval, scrollbar, scrollback, bell, and close behavior.
- Native shells, platform-specific launch choices, leader keys, and shortcuts.

The shared config leaves `default_prog` unset, allowing WezTerm to choose its
platform default shell. Windows-specific launch choices are created only on
Windows. No optional shell, shell plugin, or external command is required for
normal startup. JetBrains Mono and Nerd Font symbol fallback are bundled with
WezTerm. Transparency and decorations depend on the OS/compositor; use opacity
`1.0` if transparency is unavailable.

## Keep machine-specific profiles local

Copy the versioned [wezterm.local.lua](wezterm.local.lua) to
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

The repository copy is a public, no-op example: all overrides are commented out.
Workstation-only tools belong in your installed copy. The example shows how to
check the platform and the existence of a local initialization script before
adding its launch-menu entry. Put a multi-step setup in that local wrapper;
stop or report failures when later commands depend on earlier steps. The shared
config then remains useful on machines where those tools do not exist.

The checkout's `wezterm.local.lua` is tracked and is **not** protected by
`.gitignore`. Keep its content generic; do not put private settings there.
Other `wezterm.local.*.lua` variants remain ignored, but are not automatically
loaded. Check `git status` before committing, including in any separate dotfiles
repository that contains your home-directory copy.

If you previously kept an ignored private `wezterm.local.lua` in the checkout,
move it outside the checkout **before pulling this version**. Preserve an
existing home-directory profile rather than overwriting it. See the
[migration note](docs/SETUP.md#upgrading-from-the-ignored-local-file-layout).

A missing local file is allowed. Read errors, syntax errors, an incorrect return
type, and runtime errors surface instead of silently loading different settings.
After creating the file for the first time, reload with `Ctrl+Shift+r` or `Cmd+r`
on macOS. Existing files are registered for automatic reload on edits.

## Daily use

The default leader is **Escape** with a two-second timeout. Press Escape, release
it, then press the action key. A single Escape is consumed; timing out does not
send it to the application. Double Escape sends one literal Escape. Unmapped
keys after the leader are also consumed.

If that interferes with your editor, the local example includes a complete
`Ctrl+a` alternative. It updates the double-leader forwarding shortcut as well.
Changing the shared leader before the bindings are constructed also updates the
forwarding shortcut automatically. `Ctrl+a` has its own application conflicts;
choose according to your workflow.

For pane, tab, and window close actions, see the
[closing keymap](cheatsheets/wezterm-keymap.html#closing) and
[closing workflow](cheatsheets/wezterm-workflows.html#workflow-close). A pane close
affects one session; a tab close affects all its panes; a window close affects
all its tabs in the default local setup. Confirmation can be skipped for idle
shells. The [architecture sheet](cheatsheets/wezterm-architecture.html#lifetime)
explains lifetime, close cascades, and how remote/persistent mux setups differ.

The complete shortcut catalog belongs to the keymap, task sequences to workflows,
and object relationships to architecture. Local overrides may change the defaults.

The scrollbar is enabled in the window's right-hand padding. Use
`Shift+PageUp` / `Shift+PageDown` for quick paging, or see
[scrolling keys](cheatsheets/wezterm-keymap.html#scrolling) and the
[history workflow](cheatsheets/wezterm-workflows.html#workflow-scroll) for copy-mode
jumps and compact Mac keyboard equivalents. The active pane retains 10,000
scrollback lines by default; a local override can change that limit.

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
