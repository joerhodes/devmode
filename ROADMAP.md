# devmode — Roadmap

Known gaps and planned changes, not yet implemented.

## Only ensure Docker Desktop is running, never stop it

`devmode larakit` should keep starting Docker Desktop when it's not already
running, but `devmode herd`/`devmode stop` should stop calling `docker_mgr
"stopped"`. Docker Desktop isn't actually part of the port/DNS conflict
devmode exists to resolve — larakit's containers are. Stopping Docker
Desktop on every switch costs a slow relaunch next time it's needed, with no
corresponding conflict-avoidance benefit.

## Check for dependencies before running related commands

devmode currently assumes Homebrew, Docker Desktop, and Herd are installed
and just lets the underlying commands fail (with whatever error that
command produces) if they aren't. It should check for each dependency up
front and fail with a clear, devmode-specific message instead — e.g. `brew`
not on `PATH`, `docker` not on `PATH`, or Herd not installed (`open -a Herd`
failing). Herd should remain optional per the README; Homebrew and Docker
Desktop are hard requirements for `larakit`/`stop` but shouldn't be assumed
for `status`, which should degrade gracefully and report what's missing
rather than erroring.

## Document the bats-file fork dependency

`addTestFramework.sh` installs from `bats-core/bats-file`, not the original
`ztombol/bats-file` — the two have diverged (e.g. `assert_*_exists` aliases
exist only in the fork). This should be called out explicitly, either as a
comment in `addTestFramework.sh` or a line in the testing docs, so it reads
as a deliberate choice rather than something to "fix" later.
