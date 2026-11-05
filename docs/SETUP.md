# Setup on Windows, Linux, and macOS

This guide uses a copy-based installation with the same layout on every OS.
No symlink privileges or startup wrapper are needed. Git stores the shared
configuration; the optional private profile stays alongside your active config
in your home directory.

1. Install Git and WezTerm.
2. Clone this repository into a `wezterm-config` subfolder in your home directory.
3. Test the checkout, back up any existing active config, and copy `.wezterm.lua`
   into your home directory.
4. Optionally add `wezterm.local.lua` beside that active file.
5. Start WezTerm or reload its configuration.

Choose [Windows](#windows-powershell), [Linux](#linux), or [macOS](#macos), then
continue with [private profiles](#optional-private-profile) and
[validation](#validate-and-start).

## Before you begin

- Install [Git](https://git-scm.com/downloads) and
  [WezTerm](https://wezterm.org/installation.html). This configuration targets
  WezTerm `20240203-110809-5046fc22` or newer.
- Confirm `git --version` and `wezterm --version` work in a terminal. Reopen the
  terminal after installing if its PATH has not refreshed. See
  [executable locations](#wezterm-command-not-found) if the GUI is installed
  but the command is unavailable.
- Run the commands in a terminal on the machine being configured. Only follow
  one OS section. If `~/wezterm-config` already exists, reuse that checkout and
  follow [updates](#update-the-shared-config) instead of cloning over it.
- If the active `.wezterm.lua` is a symlink, or you already use an XDG/alternate
  config location, inspect that setup first. The copy steps below assume a
  regular home-directory config file; copying onto a symlink can modify its
  target. Keep one active installation to avoid confusing search precedence.

## Windows (PowerShell)

`$HOME` in these PowerShell commands normally refers to `%USERPROFILE%`, for
example `C:\Users\your-name`. Clone into its **subfolder**, not the existing home
directory itself.

If WinGet is available, WezTerm can be installed with:

```powershell
winget install --id wez.wezterm --exact
```

Alternatively, use the installer linked from the official installation page.
Install Git for Windows as well if `git --version` is unavailable.

Clone and inspect the shared configuration:

```powershell
git clone --branch main https://github.com/abhi-k9/wezterm-config.git "$HOME\wezterm-config"
wezterm --config-file "$HOME\wezterm-config\.wezterm.lua" show-keys --lua
```

Check the output for configuration errors before continuing. If a regular active
config already exists, make a timestamped backup, then install the shared file:

```powershell
if (Test-Path -LiteralPath "$HOME\.wezterm.lua") {
    $backupStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Copy-Item -LiteralPath "$HOME\.wezterm.lua" -Destination "$HOME\.wezterm.lua.backup-$backupStamp" -ErrorAction Stop
}
Copy-Item -LiteralPath "$HOME\wezterm-config\.wezterm.lua" -Destination "$HOME\.wezterm.lua" -ErrorAction Stop
```

The resulting layout is:

```text
%USERPROFILE%\
├── .wezterm.lua          active shared configuration
├── wezterm.local.lua    optional private configuration
└── wezterm-config\      Git checkout
```

Windows-only shell choices appear in the launcher. The shared config does not
require PowerShell 7 or any workstation-only tools for normal startup.

## Linux

Install WezTerm using the official instructions for your distribution or its
supported release package. Install Git through your distribution's package
manager if needed. No shell plugins or separately installed fonts are required
by this configuration.

In your terminal:

```sh
git clone --branch main https://github.com/abhi-k9/wezterm-config.git "$HOME/wezterm-config"
wezterm --config-file "$HOME/wezterm-config/.wezterm.lua" show-keys --lua
```

Check the output for configuration errors. Back up any regular active file and
install the shared config; `&&` prevents copying if the backup fails:

```sh
if [ -e "$HOME/.wezterm.lua" ]; then
    cp -p "$HOME/.wezterm.lua" "$HOME/.wezterm.lua.backup-$(date +%Y%m%d-%H%M%S)"
else
    true
fi && cp "$HOME/wezterm-config/.wezterm.lua" "$HOME/.wezterm.lua"
```

WezTerm uses your platform default shell. The active config is
`~/.wezterm.lua`; the optional private file is `~/wezterm.local.lua`.

## macOS

Install WezTerm using the official application download, or Homebrew if you
already use it:

```sh
brew install --cask wezterm
```

If Git is unavailable, install it using the Git download instructions or Apple's
Command Line Tools (`xcode-select --install`). Then, in Terminal or another shell:

```sh
git clone --branch main https://github.com/abhi-k9/wezterm-config.git "$HOME/wezterm-config"
wezterm --config-file "$HOME/wezterm-config/.wezterm.lua" show-keys --lua
```

Check the output for configuration errors. Back up any regular active file and
install the shared config:

```sh
if [ -e "$HOME/.wezterm.lua" ]; then
    cp -p "$HOME/.wezterm.lua" "$HOME/.wezterm.lua.backup-$(date +%Y%m%d-%H%M%S)"
else
    true
fi && cp "$HOME/wezterm-config/.wezterm.lua" "$HOME/.wezterm.lua"
```

The active files use the same home-directory layout as Linux. WezTerm uses your
platform default shell, and native Cmd shortcuts remain available. If the
application opens but `wezterm` is unavailable in Terminal, see
[executable locations](#wezterm-command-not-found).

## Optional private profile

The shared config works without a local file. For machine-only preferences or
launch profiles, choose **one** of these approaches:

- Download/copy your existing private profile from your own storage. Save it as
  `wezterm.local.lua` in your home directory, beside the active `.wezterm.lua`.
  This repository does not contain a private-profile download or private commands.
- Start with the generic example below, then edit the home-directory copy.

Keep the exact filename: on Windows, ensure it was not saved as
`wezterm.local.lua.txt`. Install a work-machine profile only on machines with its
required tools. The local file must return `function(config, wezterm)`; a complete
replacement `.wezterm.lua` is not a compatible local-profile file.

To create the generic local file **only if it does not already exist**:

Windows / PowerShell:

```powershell
if (-not (Test-Path -LiteralPath "$HOME\wezterm.local.lua")) {
    Copy-Item -LiteralPath "$HOME\wezterm-config\wezterm.local.example.lua" -Destination "$HOME\wezterm.local.lua" -ErrorAction Stop
}
```

Linux / macOS:

```sh
if [ ! -e "$HOME/wezterm.local.lua" ]; then
    cp "$HOME/wezterm-config/wezterm.local.example.lua" "$HOME/wezterm.local.lua"
fi
```

The example contains optional font/theme/shell overrides, an alternative leader,
and a generic platform/file-existence check for a machine-only launch entry.
It does not enable a work profile by itself. The private file runs after shared
settings and can append to `config.launch_menu`.

After creating it for the first time, reload manually with `Ctrl+Shift+r`, or
`Cmd+r` on macOS. Existing local files are watched for subsequent edits. Read,
syntax, return-type, and runtime errors surface rather than being silently ignored.

With this layout, the active private file is outside the checkout. If you
deliberately run the checkout's config directly, its private file instead belongs
at the checkout root, where `.gitignore` excludes it. Always check `git status`
before committing; another dotfiles repository may need its own ignore rule.

## Validate and start

Check the installed home-directory config explicitly:

Windows / PowerShell:

```powershell
wezterm --config-file "$HOME\.wezterm.lua" show-keys --lua
wezterm --config-file "$HOME\.wezterm.lua" ls-fonts
wezterm --config-file "$HOME\.wezterm.lua" start
```

Linux / macOS:

```sh
wezterm --config-file "$HOME/.wezterm.lua" show-keys --lua
wezterm --config-file "$HOME/.wezterm.lua" ls-fonts
wezterm --config-file "$HOME/.wezterm.lua" start
```

Also open WezTerm normally from your desktop/app launcher to confirm it finds the
same home-directory config. Configuration tools may fall back to defaults after
an error, so inspect diagnostics as well as the command's exit status.

Expect Catppuccin Macchiato and a bottom tab bar. Press **Escape**, release it,
then **c** to open a tab, or **p** to open the launcher. A private menu entry appears
only if your local file adds it. A single Escape acts as the leader; double Escape
sends one Escape to an application. See the
[HTML cheatsheet](../cheatsheets/wezterm-cheatsheet.html) for other workflows.

## Update the shared config

The home-directory file is a copy: `git pull` alone does not update the active
configuration. Keep personal edits in `wezterm.local.lua`; if you edited the
active `.wezterm.lua` directly, back it up and merge those edits first.

First update the checkout. Run the copy command only after the pull succeeds.

Windows / PowerShell:

```powershell
git -C "$HOME\wezterm-config" pull --ff-only
```

```powershell
Copy-Item -LiteralPath "$HOME\wezterm-config\.wezterm.lua" -Destination "$HOME\.wezterm.lua" -ErrorAction Stop
```

Linux / macOS:

```sh
git -C "$HOME/wezterm-config" pull --ff-only &&
    cp "$HOME/wezterm-config/.wezterm.lua" "$HOME/.wezterm.lua"
```

Reload with `Ctrl+Shift+r` or `Cmd+r` on macOS, then repeat the installed-config
check. These commands replace only `.wezterm.lua`; they leave your private
`wezterm.local.lua` in place. If a fast-forward pull fails, resolve the local Git
changes before copying anything.

## Troubleshooting

### WezTerm command not found

Reopen your terminal after installation, or use the actual executable's full
path. Common application locations are:

Windows / PowerShell (adjust if installed elsewhere):

```powershell
& "$env:ProgramFiles\WezTerm\wezterm.exe" --version
```

macOS (a normal application-folder install):

```sh
/Applications/WezTerm.app/Contents/MacOS/wezterm --version
```

Use that full path in place of `wezterm` in the other commands. On Linux, use
your installed package's executable or the downloaded AppImage's actual path.

### The appearance or private menu did not change

1. Confirm the active filenames and locations from the table below.
2. Check that you copied the shared config after pulling. Edits in the checkout
   do not automatically change the installed home-directory copy.
3. Try an explicit `--config-file` command from [validation](#validate-and-start).
4. If the explicit config works but normal startup differs, inspect your other
   config files and launch arguments. WezTerm also searches locations such as
   `$XDG_CONFIG_HOME/wezterm/wezterm.lua` and `~/.config/wezterm/wezterm.lua` on
   Unix. See the official [search order](https://wezterm.org/config/files.html).
5. In the debug overlay (`Ctrl+Shift+l`), inspect
   `wezterm.config_file` and `wezterm.config_dir` to find the loaded file and the
   directory used for `wezterm.local.lua`. This is also useful with symlinks.
6. Reload after creating a new local file, and check errors or the file's platform
   and availability guards if a profile is still absent.

| Role | Windows | Linux / macOS |
| --- | --- | --- |
| Git checkout | `%USERPROFILE%\wezterm-config\` | `~/wezterm-config/` |
| Active shared config | `%USERPROFILE%\.wezterm.lua` | `~/.wezterm.lua` |
| Active private profile | `%USERPROFILE%\wezterm.local.lua` | `~/wezterm.local.lua` |

### A shell or window effect is unavailable

Keep `default_prog` unset unless the selected executable is installed on that
machine. A Windows-only profile cannot initialize Windows tools on Linux/macOS.
Window transparency, blur, and decorations depend on the OS/compositor; use
`window_background_opacity = 1.0` locally if needed. Starting a GUI requires a
graphical session; `show-keys` can still inspect configuration without opening
a window.
