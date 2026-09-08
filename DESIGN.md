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

## Repo layout

```
devmode/
├── bin/
│   └── devmode                 # dispatch script + devmode:: primitives library
├── environments/
│   ├── herd.conf.sample         # baseline: Herd + Mailpit + local Forgejo
│   ├── larakit.conf.sample      # baseline: larakit compose stack + dnsmasq
│   └── example.conf.sample      # documented template; NOT globbed as a mode
├── README.md
└── tests/
    └── *.bats
```

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
