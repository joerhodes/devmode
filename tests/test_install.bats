setup() {
    load "common_setup"
    _common_setup
    PATH="${DEVMODE_HOME}:${PATH}"

    TMPDIR="$(mktemp -d)"

    # fake home
    export HOME="${TMPDIR}/home"
    mkdir -p "${HOME}"

    CONFIG_DIR="${HOME}/.config/devmode"

    # fake install directory
    export BIN_DIR="${TMPDIR}/bin"
    mkdir -p "${BIN_DIR}"
}

@test "install creates config directory" {
    assert_not_exist "${CONFIG_DIR}"

    run install.sh
    assert_success

    assert_exists  "${CONFIG_DIR}"
}

@test "install copies config files" {
    echo "herd config" > "${DEVMODE_HOME}/environments/herd.conf"
    echo "larakit config" > "${DEVMODE_HOME}/environments/larakit.conf"

    run install.sh
    assert_success

    assert_file_contains "${CONFIG_DIR}/herd.conf" "herd config" "grep"
    assert_file_contains "${CONFIG_DIR}/larakit.conf" "larakit config" "grep"

    rm "${DEVMODE_HOME}/environments/herd.conf"
    rm "${DEVMODE_HOME}/environments/larakit.conf"
}

@test "install copies sample config files" {
    run install.sh
    assert_success

    assert_file_exists "${CONFIG_DIR}/herd.conf"
    assert_file_exists "${CONFIG_DIR}/larakit.conf"
}

@test "install copies devmode to bin dir" {
    assert_not_exists "${BIN_DIR}/devmode"

    run install.sh
    assert_success

    assert_output "Installed devmode v2.3.0 to ${BIN_DIR}"

    assert_exists "${BIN_DIR}/devmode"
    assert_file_executable "${BIN_DIR}/devmode"
}
