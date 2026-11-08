#!/usr/bin/env bash
#
# Installation for devmode
#
#
set -euo pipefail

if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
  echo "Run install.sh as your normal user; it will ask for sudo only when needed." >&2
  exit 1
fi

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/devmode"


mkdir -p "${CONFIG_DIR}"

# copy *.conf if they exist, other copy the sample configs
shopt -s nullglob
configs=(environments/*.conf)
(( ${#configs[@]} )) || configs=(environments/*.conf.sample)
shopt -u nullglob

if (( ${#configs[@]} == 0 )); then
  echo "No config files found in environments/" >&2
  exit 1
fi

for f in "${configs[@]}"; do
  name=$(basename "$f" .sample)     # foo.conf.sample -> foo.conf, foo.conf -> foo.conf
  dest="$CONFIG_DIR/$name"
  if [[ -e "$dest" ]]; then
    echo "Keeping existing $dest"
  else
    cp "$f" "$dest"
  fi
done

# System part: sudo only if the bin dir isn't writable
SUDO=""
[[ -w "$BIN_DIR" ]] || SUDO="sudo"
$SUDO rm -f "$BIN_DIR/devmode"
$SUDO install -m 755 bin/devmode "$BIN_DIR/devmode"

echo "Installed $("$BIN_DIR/devmode" version) to $BIN_DIR"
