# devmode v2 — Design

## Purpose

`devmode` toggles a Mac between isolated development environments (currently
Herd/personal and larakit/work), coordinating whatever services, apps, and
system daemons each environment needs — without them conflicting with each
other on shared resources (ports, dnsmasq, etc).

v1 was a zsh-then-bash script with mode names hardcoded into the dispatch
logic and a fixed idea of "services to start/stop." v2 redesigns around two
ideas: **discoverable environments** (adding a new one is a new file, not a
script change) and **command primitives** (each environment composes small,
idempotent wrapper functions rather than the script knowing about Docker
specifically).

## Core concepts

### Environments are files, not code

An environment is a `.conf` file in `~/.config/devmode/` that defines two
bash functions:

```bash
devmode_up()   { ... }
devmode_down() { ... }
```

`devmode <name>` sources `<name>.conf` and calls `devmode_up`. The script
itself never hardcodes environment names — it discovers available modes by
globbing `*.conf` in the config directory. Adding a third environment (e.g.
a future DDEV-based stack) means dropping in a new conf file, not editing
the dispatch script.

`example.conf.sample` ships as a documented template but is **not** sourced
as a mode (see Repo Layout) — its extension deliberately doesn't match the
`*.conf` glob so it can't accidentally appear as a selectable environment.

### Command primitives (the `devmode::` namespace)

Each environment's `devmode_up`/`devmode_down` is composed from a small,
shared library of wrapper functions, namespaced with `devmode::` (a bash
naming convention, not special syntax — it just reads as module/class
scoping and makes `grep -r "devmode::"` find every primitive).

Primitives wrap the small set of tools environments actually need:

- `devmode::brew_start` / `devmode::brew_stop` — Homebrew services (e.g. dnsmasq)
- `devmode::app_launch` / `devmode::app_quit` — GUI apps via `open` / `osascript`
- `devmode::docker_start` / `devmode::docker_stop` — standalone containers
- `devmode::compose_up` / `devmode::compose_down` — docker-compose stacks

**All primitives are idempotent.** Each checks current state before acting
(`pgrep`, `docker inspect`, `brew services list`, `docker compose ps`) and
only acts if the desired state isn't already met. This means:

- `devmode_up`/`devmode_down` are safe to call redundantly or out of order.
- The same state-check used by each primitive doubles as the basis for
  `devmode status` — status reporting and actuation share detection logic
  rather than duplicating it (e.g. `devmode::app_running` is called by both
  `devmode::app_launch` and the status reporter).

### Exclusive resources and switch ordering

Idempotency alone doesn't prevent two environments from fighting over a
resource only one can hold at a time — e.g. Homebrew's dnsmasq vs Herd's
bundled dnsmasq (port 53), or larakit's compose stack vs Herd both wanting
port 80.

Each conf declares what it exclusively claims:

```bash
DEVMODE_EXCLUSIVE=("dnsmasq" "port80")
```

**Rule: on every mode switch, fully run the outgoing environment's
`devmode_down` before running the incoming environment's `devmode_up`.**
This is the one place order is enforced deliberately, rather than left to
idempotency:

```bash
devmode() {
    local new_mode="$1"
    local current
    current=$(cat ~/.config/devmode/.current 2>/dev/null)

    if [[ -n "$current" && "$current" != "$new_mode" ]]; then
        source "$HOME/.config/devmode/${current}.conf"
        devmode_down
    fi

    source "$HOME/.config/devmode/${new_mode}.conf"
    devmode_up
    echo "$new_mode" > ~/.config/devmode/.current
}
```

Not every resource an environment touches is exclusive — Docker containers
that don't collide on ports (e.g. Mailpit, Forgejo) are just wasteful, not
broken, if left running in the wrong mode. `DEVMODE_EXCLUSIVE` marks only
the resources that must be fully released before another environment can
claim them; everything else can be handled opportunistically.

### Why this stays flat, not multiplicative, as environments grow

Conflict handling is **mode-to-resource**, not mode-to-mode. Each conf
declares what it claims; nothing declares what it conflicts with another
specific mode over. The tear-down-before-switch rule doesn't need to know
how many other environments exist — it's O(1) per switch regardless of N.
A new environment just declares its own `DEVMODE_EXCLUSIVE` list and slots
in without revisiting existing ones.

The real risk as N grows is **state drift**, not switch-logic complexity —
a container stopped manually outside devmode, or a switch interrupted
mid-teardown (sleep, crashed terminal), can leave the world in a state the
next `devmode_up` doesn't expect. Two mitigations planned:

1. `devmode_up` should positively assert no other environment's exclusive
   resource is currently held (iterate all confs' `DEVMODE_EXCLUSIVE`,
   check against current state) and fail loud rather than silently contend
   for a port.
2. `devmode status` should report all exclusive resources across all known
   environments and who currently holds each — the source of truth once
   there are more environments than fit comfortably in your head.

### larakit: compose-as-a-unit, not per-container

larakit's stack is 5-6 containers listening on port 80. It's modeled as a
single compose primitive rather than N individually-tracked containers, so
the whole stack comes up/down together:

```bash
devmode::compose_up() {
    local compose_file="$1"
    docker compose -f "$compose_file" up -d
}

devmode::compose_down() {
    local compose_file="$1"
    if docker compose -f "$compose_file" ps --status running -q | grep -q .; then
        docker compose -f "$compose_file" down
    fi
}
```

```bash
# environments/larakit.conf
DEVMODE_EXCLUSIVE=("dnsmasq" "port80")

devmode_up() {
    devmode::brew_start dnsmasq
    devmode::compose_up ~/Sites/larakit/docker-compose.yml
}

devmode_down() {
    devmode::compose_down ~/Sites/larakit/docker-compose.yml
    devmode::brew_stop dnsmasq
}
```

Open question: whether Herd-side tools (Mailpit, Forgejo) should similarly
be folded into a small compose file of their own for symmetry, vs. staying
standalone containers via `devmode::docker_start`/`docker_stop`. Not
required for v1 — noted as a possible follow-up for consistency.

## Repo layout

```
devmode/
├── bin/
│   └── devmode                 # dispatch script + devmode:: primitives library
├── environments/
│   ├── herd.conf                # baseline: Herd + Mailpit + local Forgejo
│   ├── larakit.conf             # baseline: larakit compose stack + dnsmasq
│   └── example.conf.sample      # documented template; NOT globbed as a mode
├── install.sh
├── README.md
└── tests/
    └── *.bats
```

## Install

`install.sh`:

- Creates `~/.config/devmode/` if missing.
- Copies each baseline `environments/*.conf` into the config dir, **skipping
  any that already exist** so a user's customized conf is never clobbered
  by a re-run (e.g. after `git pull` picks up a new baseline environment).
- Copies `example.conf.sample` into the config dir as reference
  documentation.
- Symlinks `bin/devmode` to a location on `$PATH` (target still open — see
  below) so the live command tracks the repo checkout rather than requiring
  reinstall after every change; this matters while actively developing on
  the v2 branch.

Open questions to resolve before writing `install.sh`:

- **Symlink target.** `/usr/local/bin` is typically root-owned on Apple
  Silicon; `/opt/homebrew/bin` is usually user-writable and already on
  `$PATH`. Need to pick one (or detect) rather than assume `sudo` is fine.
- **Re-run / force-reset.** Skip-if-exists is safe by default; a `--force`
  flag to reset a conf back to baseline may be worth adding later, not
  required for v1.

## Herd baseline environment (services)

Since Herd Pro (with its built-in mail trap) isn't planned, Herd mode
needs local equivalents:

- **Mailpit** (`axllent/mailpit` Docker image) — SMTP capture + web UI,
  replaces Herd Pro's built-in trap / the team's Mailtrap usage at work.
  SMTP on `1025`, UI on `8025`.
- **local Forgejo** — self-hosted git, personal-side.

Both are personal/Herd-side tools, not work/larakit-side — work already has
Mailtrap and Bitbucket handled independently of devmode.

## Still open / deferred

- Exact schema and inline documentation for `example.conf.sample`.
- Whether Herd-side services become a small compose file (for primitive
  symmetry with larakit) or stay standalone `docker run` containers.
- `devmode status` output format — per-service state today; should extend
  to cross-environment exclusive-resource ownership as environment count
  grows.
- Symlink target and `install.sh` force/reset behavior (above).
