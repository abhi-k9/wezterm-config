# WezTerm configuration

A documented configuration for Linux, Windows, and macOS, with Catppuccin
Macchiato, a visible APP/WEZ input badge, and controls for outer tabs/panes when needed.

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

## Input modes: WezTerm → Zellij → Neovim

New windows start **APP**, forwarding ordinary application keys. **Alt+Enter**
for fullscreen and **Ctrl+Shift+F12** to toggle APP ↔ WEZ are always available.
By default **Ctrl+Shift+C/V** copy/paste the host clipboard in APP too
(**Cmd+C/V** also work on macOS).
Plain **F12** reaches Zellij for its lock toggle, and one **Escape** reaches the
application. There is no Escape leader.

Select rendered text in WezTerm, then copy directly in APP. If an inner app
captures mouse drags, hold Shift while dragging to make a WezTerm selection.
Paste goes into the focused Zellij pane; enter Insert mode first when pasting
into Neovim. Plain Ctrl+C and Ctrl+V remain application keys.

In `.wezterm.lua`, the documented `app_shortcuts` options control these APP
extensions: `enabled = false` disables both, while `copy = false` or
`paste = false` disables just that APP shortcut. WEZ always keeps both. See
[APP shortcut settings](docs/INPUT.md#configure-app-extensions) for the complete
options block and per-machine overrides in the local file.
Explicit local bindings take precedence over generated clipboard defaults.

Toggle **WEZ** for outer-terminal search/font/tab controls. In WEZ,
**Ctrl+Shift+Space**, release, then a command key opens the launcher (`p`), creates
an outer tab (`c`), closes an outer pane (`x`), etc. Return APP for daily editing.
The mode is window-local; config reloads reset APP. OS-owned controls still apply.

See [the input-routing guide](docs/INPUT.md) for the complete mode contract,
clipboard, scrolling, closing, customization, and migration from the old leader.
The Zellij F12 behavior assumes the companion configuration binds it; this repo
does not install or change Zellij/Neovim.

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
- Native shells, platform-specific launch choices, input modes, and optional APP clipboard shortcuts.

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
After creating the file for the first time, toggle WEZ, then reload with
`Ctrl+Shift+r` or `Cmd+r` on macOS. Reload returns APP. Existing files are
registered for automatic reload on edits.

## Daily use

Use Zellij for its inner terminal panes/tabs/sessions, and Neovim for editing.
In Zellij Normal, Ctrl+S enters its Scroll mode; Ctrl+B/Ctrl+F page, `u`/`d` move by
half-pages, and Ctrl+C returns to live output and Normal. Unlock Zellij with F12
first if it is Locked. These keys refer to the companion/default Zellij map.

The right-edge WezTerm scrollbar covers the active outer pane, not the independent
history of each inner Zellij pane. For a direct outer shell, toggle WEZ and use
Shift+PageUp/PageDown or its copy mode. See [scrolling keys](cheatsheets/wezterm-keymap.html#scrolling)
and [the history workflow](cheatsheets/wezterm-workflows.html#workflow-scroll).

For closing, choose the right layer: Zellij Normal, Ctrl+P then `x` closes an inner
pane; Ctrl+T then `x` closes an inner tab. WEZ prefix `x` closes an outer pane, and
WEZ Ctrl+Shift+W/Cmd+W closes an outer tab. Native window close affects all outer
tabs. An outer close disconnects its Zellij client. See the [closing keymap](cheatsheets/wezterm-keymap.html#closing),
[workflow](cheatsheets/wezterm-workflows.html#workflow-close), and
[architecture](cheatsheets/wezterm-architecture.html#lifetime).

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
Lua/configuration APIs, the APP shortcut allowlist, mode transitions, OS branches,
all APP clipboard switch combinations, optional overrides, legacy-override
rejection, resolved binding precedence, badge cache invalidation, and error paths.
Platform simulation validates configuration logic; test native shells, key
events, and window effects on each OS as well.

The badge polls the input mode every 200 ms, but caches its palette and formatted
text per window. It reads the full effective config on a cache miss or config/
window-override reload. The status setter still runs each poll: WezTerm 20240203
uses it to schedule the next poll and already avoids redraws for unchanged text.
The cache is bounded so closed windows do not accumulate entries indefinitely. Rendering
limits and scrollback remain conservative; opacity `1.0` can reduce compositing
work on machines where transparency is costly.
