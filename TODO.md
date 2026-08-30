# devmode — TODO

- **Only ensure Docker Desktop is running, never stop it.** It isn't part of
  the port/DNS conflict devmode exists to resolve — larakit's containers
  are. Auto-stopping it costs a slow relaunch next time, for no benefit.

- **Check for dependencies before running commands.** Currently assumes
  Homebrew, Docker Desktop, and Herd are installed and lets the underlying
  command fail. Should check up front and fail with a clear message.
  `status` should degrade gracefully and report what's missing rather than
  erroring; `larakit`/`stop` can fail outright on a missing hard dependency.

- **Document the bats-file fork dependency.** `addTestFramework.sh` installs
  from `bats-core/bats-file`, not the original `ztombol/bats-file` — the two
  have diverged (e.g. `assert_*_exists` aliases only exist in the fork).
  Note this is deliberate, not something to "fix."
