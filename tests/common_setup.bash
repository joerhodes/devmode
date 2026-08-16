_common_setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
    load 'helpers/bats-file/load'
    load 'helpers/bats-mock/stub'

    # get the directory for LARAKIT_HOME
    DEVMODE_HOME="$(cd -- "$(dirname -- "${BATS_TEST_FILENAME}")/.." && pwd -P)"
    DEVMODE_LIB="${DEVMODE_HOME}/lib"
}
