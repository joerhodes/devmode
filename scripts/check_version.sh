#!/usr/bin/env bash
# Verify the release version is consistent across the repo.
#
# Usage:
#   scripts/check_version.sh vX.Y.Z   # before tagging, or in CI with "$GITHUB_REF_NAME"
#   scripts/check_version.sh          # no tag: check README.md against bin/devmode
#
# Checks:
#   - bin/devmode   DEVMODE_VERSION="X.Y.Z" matches the tag (without the leading v)
#   - README.md     every devmode-vX.Y.Z reference matches the expected version
#
# Exit codes: 0 all checks passed, 1 a check failed, 2 usage or parse error.
# Written for bash 3.2 (macOS /bin/bash): no mapfile, no associative arrays.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

SCRIPT="bin/devmode"
README="README.md"
SEMVER='[0-9]+\.[0-9]+\.[0-9]+'
errors=0

pass() { echo "ok:   $*"; }
fail() { echo "FAIL: $*" >&2; errors=$((errors + 1)); }

# --- Source of truth: DEVMODE_VERSION in bin/devmode ---------------------------
script_version=$(sed -n 's/^DEVMODE_VERSION="\(.*\)"$/\1/p' "$SCRIPT")
if [[ -z "$script_version" ]]; then
  echo "Could not find DEVMODE_VERSION=\"X.Y.Z\" in $SCRIPT" >&2
  exit 2
fi
if [[ ! "$script_version" =~ ^${SEMVER}$ ]]; then
  echo "DEVMODE_VERSION must be X.Y.Z with no leading v, got: $script_version" >&2
  exit 2
fi

# --- Expected version: from the tag if given, else from the script -------------
tag="${1:-}"
if [[ -n "$tag" ]]; then
  if [[ ! "$tag" =~ ^v${SEMVER}$ ]]; then
    echo "Tag must look like vX.Y.Z, got: $tag" >&2
    exit 2
  fi
  expected="${tag#v}"
  if [[ "$script_version" == "$expected" ]]; then
    pass "$SCRIPT DEVMODE_VERSION=$script_version"
  else
    fail "$SCRIPT DEVMODE_VERSION=$script_version, expected $expected (tag $tag)"
  fi
else
  expected="$script_version"
  echo "info: no tag given; checking against DEVMODE_VERSION=$expected"
fi

# --- README.md: every devmode-vX.Y.Z reference must match ----------------------
readme_versions=$(grep -oE "devmode-v${SEMVER}" "$README" | sed 's/^devmode-v//' | sort -u || true)

if [[ -z "$readme_versions" ]]; then
  fail "$README has no devmode-vX.Y.Z references"
else
  while IFS= read -r v; do
    if [[ "$v" == "$expected" ]]; then
      pass "$README references devmode-v$v"
    else
      lines=$(grep -nF "devmode-v$v" "$README" | cut -d: -f1 | paste -sd, -)
      fail "$README references devmode-v$v on line(s) $lines, expected devmode-v$expected"
    fi
  done <<< "$readme_versions"
fi

# --- Result ------------------------------------------------------------------------
if (( errors > 0 )); then
  echo "$errors version check(s) failed" >&2
  exit 1
fi
echo "All version checks passed for $expected"
