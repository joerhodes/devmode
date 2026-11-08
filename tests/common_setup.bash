_common_setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
    load 'helpers/bats-file/load'
    load 'helpers/bats-mock/stub'

    DEVMODE_VERSION="2.3.0"

    # get the directory for DEVMODE_HOME
    DEVMODE_HOME="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")/.." && pwd -P)"
    DEVMODE_BIN="${DEVMODE_HOME}/bin"

    # make sure devmode is in the path
    PATH="${DEVMODE_BIN}:${PATH}"
}
