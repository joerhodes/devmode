# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

`devmode` is a single-file bash CLI (`bin/devmode`) that switches a Mac between isolated local development environments (e.g. Herd/personal and larakit/work) by coordinating services — Homebrew daemons, GUI apps, Docker containers, compose stacks — so they never conflict on shared ports or DNS.

## Architecture

### Two-layer design

**`bin/devmode`** is the entire script. It contains two things:

1. A library of `devmode::` primitives — small, idempotent wrapper functions for brew, docker, compose, and GUI apps. Each primitive checks current state before acting and doubles as the detection logic for `devmode status`.
2. Dispatch logic (`main`) that discovers environments from `~/.config/devmode/*.conf` and calls `devmode_up` / `devmode_down` / `devmode_status` from the sourced conf.

**`~/.config/devmode/*.conf`** files define environments. Each conf must implement exactly three functions:
- `devmode_up` — bring resources up
- `devmode_down` — tear resources down  
- `devmode_status` — report current state (print one line per resource, aggregate return: 0 only if all up)

`environments/*.conf.sample` files are the shipped templates. Files ending in `.conf.sample` are deliberately excluded from the `*.conf` glob — they can never accidentally appear as selectable environments.

### Adding an environment

Drop a new `<name>.conf` into `~/.config/devmode/`. No changes to `bin/devmode` needed — it discovers environments by globbing. Compose each function from `devmode::` primitives; only call external CLIs directly when the environment already wraps its own compose/container management.

### Idempotency contract

Every `devmode::` primitive checks current state first and no-ops if already in the target state. `devmode_up`/`devmode_down` must not short-circuit on the first failure — accumulate `status=1` and keep going so partial failures are reported but don't abandon the rest of the stack.

### Sourcing vs. executing

`bin/devmode` guards `main` with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` so BATS tests can source it without triggering execution.

## Testing

Install the BATS framework first (one-time, run from project root):

```bash
./addTestFramework.sh
```

Upgrade installed helpers:

```bash
./addTestFramework.sh --upgrade
```

Run all tests:

```bash
./tests/bats/bin/bats tests/
```

Run a single test file:

```bash
./tests/bats/bin/bats tests/test_devmode.bats
```

Tests use `bats-mock` (stub/unstub) to intercept external commands (`docker`, `launchctl`, `sudo`, `pgrep`, etc.) and `bats-assert` for assertions. The `bats-file` helper comes from `bats-core/bats-file` (not the original `ztombol/bats-file`) — this is intentional; the two forks have diverged and `assert_*_exists` aliases only exist in the `bats-core` fork.

`DEVMODE_CONFIG_DIR` is overridden to a `mktemp -d` temp directory in each test's `setup()`, so tests never touch `~/.config/devmode/`.
