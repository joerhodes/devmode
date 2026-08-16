#!/usr/bin/env bash
#
# Install the BATS testing framework and helpers.
#
# References:
#     https://github.com/bats-core/bats-core
#     https://github.com/bats-core/bats-support
#     https://github.com/bats-core/bats-assert
#     https://github.com/bats-core/bats-file
#     https://github.com/buildkite-plugins/bats-mock
set -euo pipefail

LARAKIT_HOME="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BATS_HOME="${LARAKIT_HOME}/tests/bats"
BATS_HELPER="${LARAKIT_HOME}/tests/helpers"
CURRENT_DIR="$(pwd -P)"

[ "${CURRENT_DIR}" != "${LARAKIT_HOME}" ] && {
    printf "\nERROR: This script must be run from %s\n" "${LARAKIT_HOME}"
    exit 1
}

installBatsCore() {
    local ref="$1"

    if [ -f "${BATS_HOME}/bin/bats" ]; then
        if [ "${UPGRADE:-0}" -eq 1 ]; then
            printf "Upgrading bats-core to %s.\n" "${ref}"
            (
                cd "${BATS_HOME}" && \
                git fetch --quiet && \
                git checkout --quiet "${ref}"
            ) || return 1
        else
            printf "bats-core already installed.\n"
        fi
        return 0
    fi

    printf "Installing bats-core (%s).\n" "${ref}"

    mkdir -p "${BATS_HOME}"
    git clone -q https://github.com/bats-core/bats-core.git "${BATS_HOME}" || return 1
    (cd "${BATS_HOME}" && git checkout --quiet "${ref}") || return 1
}

# Install a bats helper under test/helpers
#     $1 - help name, ie bats-support
#     $2 - git clone url
#     $3 - ref to checkout
installBatsHelper() {
    local module="$1" gitUrl="$2" ref="$3"

    if [ -d "${BATS_HELPER}/${module}" ]; then
        if [ "${UPGRADE:-0}" -eq 1 ]; then
            printf 'Upgrading %s to %s.\n' "${module}" "${ref}"
            (cd "${BATS_HELPER}/${module}" && git fetch -q && git checkout -q "${ref}") || return 1
        else
            printf '%s already installed.\n' "${module}"
        fi
        return 0
    fi

    printf 'Installing %s (%s).\n' "${module}" "${ref}"
    git clone -q "${gitUrl}" "${BATS_HELPER}/${module}" || return 1
    (cd "${BATS_HELPER}/${module}" && git checkout -q "${ref}") || return 1
}

[[ "${1:-}" == "--upgrade" ]] && UPGRADE=1

installBatsCore 'v1.14.0'
installBatsHelper 'bats-support' 'https://github.com/bats-core/bats-support.git' 'v0.3.0'
installBatsHelper 'bats-assert' 'https://github.com/bats-core/bats-assert.git' 'v2.2.4'
installBatsHelper 'bats-file' 'https://github.com/bats-core/bats-file.git' 'v0.4.0'
installBatsHelper 'bats-mock' 'https://github.com/buildkite-plugins/bats-mock.git' 'v2.2.0'
