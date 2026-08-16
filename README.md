# devmode

Zsh functions and aliases for switching between **work** (larakit / Docker) and
**personal** (Laravel Herd) local development environments on macOS — without
the two stepping on each other.

## Why this exists

Both larakit (a Laradock wrapper used for work projects under `~/Sites`) and
Laravel Herd (used for personal Laravel projects, kept in a separate
directory) provide their own PHP, Composer, nginx, and dnsmasq. Run both at
once and you get collisions:

- **Port 80/443** — both want to bind them.
- **`.test` domain resolution** — Homebrew's dnsmasq (used by larakit) and
  Herd's bundled dnsmasq both try to own `*.test`, and whichever one is
  active determines what actually resolves.
- **PHP/Composer on `PATH`** — plain `php`/`composer` in a shell resolve to
  whichever stack's binaries got there first, not necessarily the one you
  meant for the project you're in.

`devmode` gives you one command to declare which world you're working in, and
handles bringing the right stack up and the other one fully down — Docker
containers, dnsmasq, and PHP/Composer resolution together — so you're never
left in a half-switched state.

## Requirements

- macOS with [Homebrew](https://brew.sh)
- [zsh](https://www.zsh.org) (default macOS shell)
- [larakit](../larakit) installed and configured for work projects
- [Laravel Herd](https://herd.laravel.com) installed for personal projects
  (optional — devmode degrades gracefully if Herd isn't installed)

## Installation

```zsh
git clone <this-repo> ~/.devmode
echo 'source ~/.devmode/devmode.zsh' >> ~/.zshrc
```

Restart your shell or `source ~/.zshrc`.

### Optional: passwordless sudo for dnsmasq

Homebrew's dnsmasq binds port 53, a privileged port, so starting/stopping it
requires `sudo`. By default, `devmode` will prompt for your password when
needed. If you'd rather not be prompted on every switch, you can grant
passwordless sudo scoped narrowly to the two commands devmode actually runs:

```
# via `sudo visudo`, add a line scoped to your user:
yourusername ALL=(root) NOPASSWD: /opt/homebrew/bin/brew services start dnsmasq, /opt/homebrew/bin/brew services stop dnsmasq
```

This is optional and changes your system's sudo behavior — do it
deliberately, not by habit. Scope it to exactly those two commands rather
than a broader `brew services *` wildcard.

## Usage

```zsh
devmode larakit     # bring up larakit, stop Herd, ensure brew dnsmasq is running
devmode herd         # bring up Herd, stop larakit, stop brew dnsmasq
devmode stop         # stop both environments
devmode status       # show current state of both stacks
```

Each mode switch handles, together, so you're never left half-switched:

| | Docker (larakit) | Brew dnsmasq | Herd |
|---|---|---|---|
| `devmode larakit` | up | started | stopped |
| `devmode herd` | down | stopped | started |
| `devmode stop` | down | stopped | stopped |

Modes are named after the tool rather than "work"/"personal" — Herd is
expected to eventually replace larakit outright rather than stay a permanent
personal-only counterpart, so the naming doesn't assume that split is
permanent.

## How status checks work

Homebrew's dnsmasq and Herd's bundled dnsmasq are both processes literally
named `dnsmasq`, so a plain `pgrep dnsmasq` can't tell them apart. devmode
checks Homebrew's dnsmasq specifically by its LaunchDaemon label instead:

```zsh
launchctl print system/homebrew.mxcl.dnsmasq >/dev/null 2>&1
```

This only matches the Homebrew-managed system LaunchDaemon
(`/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist`), not Herd's own
bundled dnsmasq binary, which runs under Herd's own helper service and isn't
registered under a `homebrew.mxcl.*` label.

## File layout

Sourced function/alias files use the `.zsh` extension (the de facto
convention in the zsh ecosystem — oh-my-zsh, zinit, prezto — as opposed to
larakit's `.bash` files, which are sourced by a bash-based tool):

```
devmode.zsh          # entry point, sources the files below
lib/
  larakit.zsh         # start/stop larakit's Docker stack
  dnsmasq.zsh          # brew dnsmasq status/start/stop
  herd.zsh             # start/stop Herd, guards for "Herd not installed"
tests/
  *.bats                # BATS tests for status-check logic
```

## Known limitations

- macOS DNS resolver changes don't always take effect instantly after a
  switch. If `.test` domains resolve inconsistently right after switching
  modes, try `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`.
  In rare cases a full restart has been needed to clear a stuck state.
- Custom TLDs in Herd are no longer officially supported by Laravel, so this
  project assumes both larakit and Herd use the default `.test` TLD and
  relies on the toggle (rather than separate TLDs) to avoid collisions.

## Status

Early stage — built for personal use, being cleaned up for sharing with
other developers. Not yet published.
