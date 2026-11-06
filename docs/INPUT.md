# Input routing: WezTerm → Zellij → Neovim

The shared config starts each WezTerm window in **APP** mode. WezTerm reserves
fullscreen and the mode toggle, plus enabled APP extensions (host copy/paste
by default), then lets the terminal application handle other keys.
Use **WEZ** mode temporarily for outer-terminal controls. The tab-bar badge
shows `APP`, `WEZ`, or `WEZ · CMD` while a one-shot command is pending.

## Keys available in APP

| Key | Owner and action |
| --- | --- |
| `Alt+Enter` | WezTerm: toggle fullscreen in either mode. |
| `Ctrl+Shift+F12` | WezTerm: toggle APP ↔ WEZ for this GUI window. |
| `Ctrl+Shift+C` | Copy the WezTerm selection to the host clipboard. APP extension, enabled by default; always available in WEZ. |
| `Ctrl+Shift+V` | Paste the host clipboard into the focused terminal. APP extension, enabled by default; always available in WEZ. |
| `Cmd+C` / `Cmd+V` (macOS) | The same copy/paste actions and APP extension settings. |

Fullscreen and the mode toggle are always reserved. The clipboard extensions
are controlled by the settings below; disabling one in APP forwards that chord
to the application instead. This does not disable mouse or OS menu actions.

Plain `F12` is forwarded for Zellij's lock toggle. It does not change WezTerm's
mode. Ordinary Escape is sent onward immediately; the old Escape leader and
double-Escape workaround are gone. On laptops/compact keyboards, check Fn/Fn-lock:
the F12 position may send a media key instead. Hold Fn if needed; the WezTerm
toggle then uses `Ctrl+Shift+Fn+F12`. The window manager or OS can reserve
combinations before WezTerm receives them.

The [companion Zellij configuration](https://github.com/abhi-k9/zellij-config)
binds F12 to Normal ↔ Locked. Upstream Zellij defaults may differ. This repo
does not install or modify Zellij or Neovim.

## Configure APP extensions

The `.wezterm.lua` input section contains these ordinary Lua options:

```lua
local app_shortcuts = {
  enabled = true, -- Master switch for all optional APP shortcuts.
  copy = true,    -- Ctrl+Shift+C; also Cmd+C on macOS.
  paste = true,   -- Ctrl+Shift+V; also Cmd+V on macOS.
}
```

- Set `enabled = false` for APP with only fullscreen and the mode toggle.
- Keep `enabled = true` and set `copy = false` or `paste = false` to disable
  just that APP extension. Both enabled means copy and paste work directly in APP.
- WEZ always keeps both clipboard shortcuts, regardless of these options.
  Plain Ctrl+C (interrupt) and Ctrl+V (application behavior) are never bound here.

The switches control the shared APP defaults. Explicit global `config.keys`
bindings in the local file take precedence, including chords WezTerm normalizes
to the same key. Disabling an extension does not remove your own global binding
for that chord. Option names and boolean values are validated so a typo does not
silently leave an extension enabled.

For a per-machine preference, accept the optional third argument in the
installed `wezterm.local.lua` function and change its fields:

```lua
return function(config, wezterm, app_shortcuts)
  app_shortcuts.enabled = false
  -- Or keep the master enabled and disable one extension:
  -- app_shortcuts.copy = false
  -- app_shortcuts.paste = false
  -- Keep existing appearance settings and launch-menu entries here.
end
```

Add the argument and settings to an existing function; preserve its private
launch entries. Existing two-argument functions continue to work because Lua
ignores extra arguments. These options are not WezTerm configuration fields:
do not set `config.app_shortcuts`. The shared config builds the optional global
bindings after applying local preferences. A missing local file uses the shared
defaults. Reload after changing the settings; the badge returns to APP.

## What the modes do

| State | Keyboard routing |
| --- | --- |
| APP | Fullscreen, the toggle, and enabled clipboard extensions belong to WezTerm. Other input follows the normal terminal path to Zellij/the shell. |
| WEZ | The explicit WezTerm control table always includes copy/paste and adds search, fonts, tabs, scrolling, debug, and the command prefix. Unmatched keys still go onward. |
| WEZ · CMD | After `Ctrl+Shift+Space` in WEZ, the next command key selects an outer-terminal action. One command or a two-second timeout returns to WEZ. |

In WEZ, `Ctrl+Shift+Space`, release, then `p` opens the launcher; `c` opens an
outer tab; `x` closes an outer pane. All prefix commands are in the
[keymap](../cheatsheets/wezterm-keymap.html). The prefix has no WezTerm binding
in APP. Escape cancels a pending prefix and sends one Escape to the application.
An unknown command cancels the prefix and follows normal WEZ routing. F12 stays
available to Zellij, including when a prefix is pending.

The mode belongs to the **WezTerm GUI window**, covering its outer tabs/panes.
Other windows have independent modes. New windows start APP; reloading the
configuration clears key-table activations and returns windows to APP. The
choice is not saved across restart and is not inferred from process names,
SSH/WSL connections, or Zellij's lock state.

Badge colors are cached per window and refreshed on config reload or a
`set_config_overrides` change. Unchanged polls reuse prepared text, while the
status setter keeps WezTerm 20240203's polling timer alive. WezTerm avoids redraws
for unchanged text; the cache is bounded independently of mode state.

In WEZ, WezTerm's copy/search/picker UIs temporarily handle their UI keys.
The mode toggle closes its copy/search UI when returning to APP. APP is a
keyboard-routing policy: it does not disable mouse bindings, the scrollbar,
native window controls, or OS/application-menu actions. Terminal encoding still
applies; forwarding does not guarantee every modified key is distinguishable
under every terminal protocol.

## Daily editing

1. Leave the outer window in APP and start Zellij with your normal launcher.
2. Open Neovim in a Zellij pane. Press F12 until Zellij indicates Locked when
   you want its ordinary shortcuts to reach Neovim.
3. Use Escape normally to leave Neovim insert mode. Alt+Enter remains available
   for fullscreen and does not change Zellij's lock state.
4. Unlock Zellij with F12 when you need its pane/tab/session controls.
5. For an outer-terminal task, toggle WEZ, use its control/prefix, then toggle
   back to APP. This does not lock or unlock Zellij.

Keep the outer tab bar visible so the mode badge remains visible. `WEZ` means
outer shortcuts are active even if the selected inner application is Neovim.

## Scrolling: choose the history that contains the output

For a shell/build pane **inside Zellij**, use its per-pane history:

1. In APP, ensure Zellij is Normal (F12 unlocks it when Locked).
2. Press `Ctrl+s` for Zellij Scroll mode.
3. Use `Ctrl+b` / `Ctrl+f` or PageUp / PageDown for pages; `u` / `d` for half-pages.
4. `Ctrl+c` scrolls to the bottom and returns Zellij to Normal. F12 can then
   return it to Locked for Neovim. Escape/Enter also leave Scroll mode.

These Scroll-mode keys reflect Zellij 0.45.1's default map retained by the
companion config. In Locked mode, `Ctrl+s` reaches the inner application instead.
Neovim has its own buffer navigation; a full-screen editor is not a terminal log.

For a shell **directly in WezTerm**, toggle WEZ and use Shift+PageUp/PageDown.
On compact Mac keyboards those are Shift+Fn+Up/Down. WEZ prefix `[` opens
WezTerm copy mode, where `g` / `Shift+g` jump to the oldest/newest retained output
and `q` exits. The right-edge scrollbar represents the active **outer** WezTerm
pane; it cannot select or expose each inner Zellij pane's independent history.
Zellij/full-screen apps may use the alternate screen, so normal outer scrollback
may not contain the output you want. Each layer retains its own history.

## Clipboard

With the default APP extensions, paste from the **host** clipboard with
`Ctrl+Shift+V` without a mode switch; `Cmd+V` also works on macOS. The text goes
into the focused Zellij pane. Enter Neovim Insert mode first when pasting into
an editor buffer. If APP paste is disabled, enter WEZ for the same shortcut.
Plain `Ctrl+V` remains an application key, so it can retain Neovim block selection
or shell behavior. It is not the terminal clipboard shortcut. Under traditional
terminal encoding, forwarding Ctrl+Shift+V can produce the same control character
as Ctrl+V (`^V`); the global paste action avoids that ambiguity.

Use the configured Neovim clipboard provider and Zellij copy operation for inner
selections; OSC52 can carry clipboard writes to the host terminal through an
appropriate setup. This repo does not configure Neovim's clipboard provider.

To copy rendered text, make a **WezTerm selection** and press `Ctrl+Shift+C`
(Cmd+C on macOS). This works directly in APP by default; if APP copy is disabled,
enter WEZ for that shortcut. Hold Shift while dragging when Zellij/Neovim captures
the mouse, so WezTerm makes the selection. The keyboard shortcut copies an
existing selection; it does not choose text or yank Neovim's visual selection.
Plain Ctrl+C still reaches the application for interrupting a command.

A WezTerm selection covers the rendered outer terminal, not a semantic selection
of an inner editor buffer. Test with non-sensitive text locally and through any
SSH/WSL path you use.

## Closing and persistence

| Intended scope | Action |
| --- | --- |
| Neovim editor/window | Use Neovim's save/quit commands, such as `:wq` or `:q`; a parent shell can remain. |
| Inner Zellij pane | In Zellij Normal, `Ctrl+p`, then `x`. |
| Inner Zellij tab | In Zellij Normal, `Ctrl+t`, then `x`; this affects all its inner panes. |
| Detach Zellij client | In Zellij Normal, `Ctrl+o`, then `d`; reattach later with the appropriate session name. |
| Outer WezTerm pane | Toggle WEZ, then `Ctrl+Shift+Space`, release, `x`. |
| Outer WezTerm tab | In WEZ, `Ctrl+Shift+W` or Cmd+W on macOS; this affects all its outer panes. |
| Native window | Use the OS close button (Alt+F4 on Windows); all its outer tabs are affected. |

Closing an outer pane/window disconnects the Zellij client hosted there. Whether
its session survives depends on Zellij's server and `on_force_close` policy;
the companion shared config chooses `detach`. Detach explicitly when preserving
the session is your intent. This is separate from a WezTerm mux server or remote
domain. Save application data before closing any scope.

Outer close actions request confirmation, but safe/idle processes may be exempt.
They are not inner-pane confirmation controls. In APP, `Ctrl+Shift+W` is forwarded
instead of closing the outer tab; the receiving application may assign it.

## Upgrade from the Escape-leader configuration

1. Pull the repository and copy its `.wezterm.lua` to the active home-directory
   location using the [setup guide](SETUP.md#update-the-shared-config).
2. Keep your private home-directory `wezterm.local.lua`. Launch-menu-only
   profiles remain compatible. Remove any enabled legacy `config.leader` or
   `config.disable_default_key_bindings = false` override; the shared config
   rejects these because they defeat APP routing.
3. Reload using the shortcut in your **currently running** config. With the old
   map that is Ctrl+Shift+R/Cmd+R. With the new map, first toggle WEZ, then reload.
   A reload returns the badge to APP and does not restart terminal applications.
4. Replace the old Escape sequences with WEZ mode plus Ctrl+Shift+Space. One
   Escape now reaches the application; no double-press is needed.

The public local example shows how to add a WEZ-only binding, change the global
toggle, or change the WEZ prefix. Put additional outer shortcuts in
`config.key_tables.wezterm`. Adding bindings to `config.keys` adds exceptions in
APP too. Defaults remain disabled; macOS Cmd+C/V follow the APP extension settings,
and the other configured Cmd equivalents are WEZ-only. A local override must
preserve these routing rules.

Direct shifted number/font shortcuts use physical number-row and +/- key
positions, so Shift does not turn the matching key into punctuation. The
command prefix uses a mapped space character; its command letters follow the
keyboard layout.

## Verify on each machine

- New window: APP badge; one Escape reaches Neovim and plain F12 changes only
  Zellij's mode. Check ordinary editing keys and Ctrl/Alt combinations you use.
- With default extensions: copy a WezTerm selection with Ctrl+Shift+C and paste
  with Ctrl+Shift+V in APP and WEZ (Cmd+C/V also work on macOS). Ctrl+C/Ctrl+V
  keep their application behavior.
- Disable an APP extension and reload: that chord goes to the application in
  APP; its host-clipboard action still works in WEZ. Disabling the master leaves
  only fullscreen and the toggle reserved in APP.
- Both modes: Alt+Enter toggles fullscreen. Ctrl+Shift+F12 changes only the current
  WezTerm window, without changing Zellij's lock state.
- WEZ: prefix `p` opens the launcher; fonts/clipboard work; returning APP releases
  WezTerm copy/search input capture. Another new window still starts APP.
- Scrolling: Zellij's Scroll mode reads the intended inner pane; the outer
  scrollbar is not used as an inner-pane history selector.
- Reload: badge returns APP; private launch entries are still available in the
  WEZ launcher. Native OS shortcuts may require changing a conflicting system
  shortcut or the local toggle chord. Check Fn/Fn-lock if F12 is not arriving.

The automated config tests exercise all OS branches and event actions with the
real WezTerm Lua/schema API. Native keyboard, OS shortcut, and terminal encoding
behavior must also be checked on the relevant platform.
