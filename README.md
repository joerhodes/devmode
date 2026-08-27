# devmode

A command-line tool for switching between **larakit** (work, Docker-based)
and **Herd** (personal Laravel projects) local development environments on
macOS — without the two conflicting over ports and DNS.

## Requirements

- macOS with [Homebrew](https://brew.sh)
- larakit installed and configured for work projects
- [Docker Desktop](https://www.docker.com/products/docker-desktop/), ideally
  4.37+ for automatic start/stop support
- [Laravel Herd](https://herd.laravel.com) installed for personal projects
  (optional — devmode degrades gracefully if Herd isn't installed)

## Installation

```bash
git clone <this-repo> ~/projects/devmode
sudo ln -s ~/projects/devmode/devmode /usr/local/bin/devmode
chmod +x ~/projects/devmode/devmode
```

### About the sudo prompt

Homebrew's dnsmasq binds port 53, a privileged port, so starting/stopping it
requires `sudo`. `devmode` prints a short message explaining why before the
prompt appears (e.g. "Starting dnsmasq requires your password.").


## Usage

```bash
devmode larakit   # start dnsmasq + Docker Desktop + larakit, stop Herd
devmode herd       # stop larakit + dnsmasq, start Herd
devmode stop       # stop everything
devmode status     # show current state of dnsmasq, Docker, larakit, and Herd
```

Each mode switch handles its stack together, so you're never left
half-switched:

| | Brew dnsmasq | Docker Desktop | larakit | Herd |
|---|---|---|---|---|
| `devmode larakit` | started | started (if needed) | up | stopped |
| `devmode herd` | stopped | stopped | down | started |
| `devmode stop` | stopped | stopped | down | stopped |

`devmode status` prints a colored dot per service (green = running, red =
stopped):

```
● dnsmasq running
● docker running
● larakit running
```

## Testing

To run tests, first install BATS and its helpers by running the `addTestFramework.sh` command.  

```bash
./test/bats/bin/bats tests/
```

## Known limitations

- macOS DNS resolver changes don't always take effect instantly after a
  switch. If `.test` domains resolve inconsistently right after switching
  modes, try `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`.
  In rare cases a full restart has been needed to clear a stuck state.
- Custom TLDs in Herd are no longer officially supported by Laravel, so this
  project assumes both larakit and Herd use the default `.test` TLD.
- Automatic Docker Desktop start/stop requires Docker Desktop 4.37+; on
  older versions, devmode reports that Docker needs to be started manually.

## Status

Working and tested. Being cleaned up for sharing with other developers.
Not yet published.
