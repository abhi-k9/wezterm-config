# Input routing: WezTerm → Zellij → Neovim

The shared config starts each WezTerm window in **APP** mode. WezTerm reserves
two keyboard shortcuts, then lets the terminal application handle other keys.
Use **WEZ** mode temporarily for outer-terminal controls. The tab-bar badge
shows `APP`, `WEZ`, or `WEZ · CMD` while a one-shot command is pending.

## The two always-on keys

| Key | Owner and action |
| --- | --- |
| `Alt+Enter` | WezTerm: toggle fullscreen in either mode. |
| `Ctrl+Shift+F12` | WezTerm: toggle APP ↔ WEZ for this GUI window. |

Plain `F12` is forwarded for Zellij's lock toggle. It does not change WezTerm's
mode. Ordinary Escape is sent onward immediately; the old Escape leader and
double-Escape workaround are gone. On compact Mac keyboards, sending F12 may
require Fn; the WezTerm toggle then uses `Ctrl+Shift+Fn+F12`. The window manager
or OS can reserve combinations before WezTerm receives them.

The [companion Zellij configuration](https://github.com/abhi-k9/zellij-config)
binds F12 to Normal ↔ Locked. Upstream Zellij defaults may differ. This repo
does not install or modify Zellij or Neovim.

## What the modes do

| State | Keyboard routing |
| --- | --- |
| APP | Only the two global bindings above belong to WezTerm. Other input follows the normal terminal path to Zellij/the shell. |
| WEZ | The explicit WezTerm control table adds clipboard, search, fonts, tabs, scrolling, debug, and the command prefix. Unmatched keys still go onward. |
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

In APP, Neovim and Zellij own their keyboard copy/paste behavior. Use the
configured Neovim clipboard provider and Zellij copy operation for inner
selections; OSC52 can carry clipboard writes to the host terminal through an
appropriate setup. This repo does not configure Neovim's clipboard provider.

To paste from the **host** clipboard, toggle WEZ, use `Ctrl+Shift+V` (Cmd+V on
macOS), then return APP. To copy an outer-terminal selection use `Ctrl+Shift+C`
(Cmd+C on macOS) in WEZ. A WezTerm selection is a selection of the rendered
outer terminal, not a semantic selection of an inner editor buffer. Test with
non-sensitive text locally and through any SSH/WSL path you use.

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
APP too. Defaults remain disabled; macOS Cmd equivalents are explicitly listed
in the WEZ table. A local override must preserve these routing rules.

Direct shifted number/font shortcuts use physical number-row and +/- key
positions, so Shift does not turn the matching key into punctuation. The
command prefix uses a mapped space character; its command letters follow the
keyboard layout.

## Verify on each machine

- New window: APP badge; one Escape reaches Neovim and plain F12 changes only
  Zellij's mode. Check ordinary editing keys and Ctrl/Alt combinations you use.
- Both modes: Alt+Enter toggles fullscreen. Ctrl+Shift+F12 changes only the
  current WezTerm window, without changing Zellij's lock state.
- WEZ: prefix `p` opens the launcher; fonts/clipboard work; returning APP releases
  WezTerm copy/search input capture. Another new window still starts APP.
- Scrolling: Zellij's Scroll mode reads the intended inner pane; the outer
  scrollbar is not used as an inner-pane history selector.
- Reload: badge returns APP; private launch entries are still available in the
  WEZ launcher. Native OS shortcuts may require changing a conflicting system
  shortcut or the local toggle chord.

The automated config tests exercise all OS branches and event actions with the
real WezTerm Lua/schema API. Native keyboard, OS shortcut, and terminal encoding
behavior must also be checked on the relevant platform.
