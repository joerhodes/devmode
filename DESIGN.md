# devmode — Design Notes

Rationale and implementation decisions behind devmode, for anyone reviewing
or extending the code. Day-to-day usage is covered in README.md; this file
is about *why* it's built this way.

## Why this exists

Both larakit (a Laradock wrapper used for work projects under `~/Sites`) and
Laravel Herd (used for personal Laravel projects, kept in a separate
directory) provide their own PHP, Composer, nginx, and dnsmasq. Run both at
once and you get collisions:

- **Port 80/443** — both want to bind them.
- **`.test` domain resolution** — Homebrew's dnsmasq (used by larakit) and
  Herd's bundled dnsmasq both try to own `*.test`, and whichever one is
  active determines what actually resolves.
- **The Docker daemon** — larakit needs Docker Desktop running; nothing
  should have to remember to check that by hand.

devmode gives one command to declare which environment you want, and
handles bringing the right stack up and the other one fully down — Docker
Desktop, dnsmasq, larakit's containers, and Herd together — so you're never
left in a half-switched state.

## Standalone script, not a sourced library

Early versions of devmode were built as sourced zsh functions, on the
assumption that PHP/Composer PATH switching would need to happen in the
calling shell. That need never materialized — Herd's own `php`/`composer`
aliasing handles that separately — and `devmode status` derives everything
from live process/container state rather than shell state. So there's
nothing here that actually requires being sourced. A standalone script is
easier to test with BATS and more portable than a zsh-specific sourced
library.

## Why installed system-wide (`/usr/local/bin`), not per-user

The dnsmasq service devmode manages is a system-level LaunchDaemon — there's
only one instance of it on the machine, shared across any logins, not
something each user account could have its own copy of. Adding devmode to a
single user's `PATH` (as would make sense for a purely per-user tool) would
be misleading given the resource it manages isn't per-user. `sudo` is only
needed for the one-time symlink step; day-to-day use doesn't require it
aside from the dnsmasq start/stop calls, which explain themselves at the
point they prompt.

## How status checks work

- **Homebrew's dnsmasq** — Homebrew's and Herd's dnsmasq are both processes
  literally named `dnsmasq`, so a plain `pgrep dnsmasq` can't tell them
  apart. devmode checks Homebrew's specifically by its LaunchDaemon label:
  `launchctl print system/homebrew.mxcl.dnsmasq`. This only matches the
  Homebrew-managed system LaunchDaemon, not Herd's bundled dnsmasq binary,
  which isn't registered under a `homebrew.mxcl.*` label.
- **Docker** — `docker info` confirms the daemon is actually responding, not
  just that some process exists.
- **larakit** — checked by looking for running containers named with the
  `laradock-` prefix.

## Starting Docker Desktop and Herd

- **Docker Desktop** — if `docker desktop` CLI commands are available
  (4.37+), devmode uses `docker desktop start`/`stop` to manage it. These
  commands block until the operation completes, so devmode doesn't need to
  poll or wait afterward. On older Docker Desktop versions without this CLI,
  devmode reports that Docker needs to be started manually instead of
  attempting to launch it.
- **Herd** — started with `open -a Herd`. Unlike `docker desktop start`,
  `open` returns as soon as the launch is requested, not once Herd is
  actually ready. Nothing in devmode currently depends on Herd being
  immediately usable after `devmode herd` returns, so this is intentional
  and not polled.

## Shared start/stop logic

`larakit_mgr` and `homebrew_dnsmasq_mgr` follow the same "compare requested
state to current state, start or stop as needed" shape. That shared logic
lives in one place (`generic_mgr`) and is called with a prefix identifying
which set of `_status`/`_start`/`_stop` functions to use, rather than being
duplicated per service.

## Testability

`main` is guarded so the script can be sourced by BATS without triggering
real execution:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

Tests stub external commands (`docker`, `launchctl`, `sudo`, `open`) at the
boundary and override internal functions (e.g. `larakit_status`,
`homebrew_dnsmasq_start`) directly to test branching logic in isolation from
the functions it calls — see `larakit_mgr`/`homebrew_dnsmasq_mgr` tests for
the pattern.

## Naming

Commands are named after the tool (`devmode larakit`, `devmode herd`)
rather than a role like "work"/"personal" — Herd eventually eventually
replace larakit outright rather than stay a permanent personal-only
counterpart, so the naming doesn't assume that split is permanent.
