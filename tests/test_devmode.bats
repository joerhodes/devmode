setup() {
    load "common_setup"
    _common_setup

    TMPDIR="$(mktemp -d)"

    load "${DEVMODE_HOME}/devmode"
}

teardown() {
    rm -rf "${TMPDIR}"
}

@test "usage displays usage" {
    run usage
    assert_success
    assert_line --index 0 "Usage: devmode mode"
    assert_line --index 1 --regexp "[[:space:]]herd[[:space:]]Start the Herd.+"
    assert_line --index 2 --regexp "[[:space:]]larakit[[:space:]]Start the larakit.*"
    assert_line --index 3 --regexp "[[:space:]]status[[:space:]]Display .* status\."
    assert_line --index 4 --regexp "[[:space:]]stop[[:space:]]Stop all .*"
}

@test "logmsg without arguments shows unknown message" {
    run logmsg
    assert_failure # exit code is non-zero

    assert_output "Error: Invalid call or Unknown error"
}

@test "logmsg displays passed message" {
    run logmsg "Warning" "test message"
    assert_failure # exit code is non-zero

    assert_output "Warning: test message"
}

@test "display_status fails without arguments" {
    run display_status
    assert_failure
}

@test "display_status shows module is running" {
    run display_status "module" 0
    assert_success

    assert_output --partial "module running"
}

@test "display_status shows module is stopped" {
    run display_status "module" 1
    assert_success

    assert_output --partial "module stopped"
}

@test "homebrew_dnsmasq_status returns success if running" {
    stub launchctl "exit 0"

    run homebrew_dnsmasq_status
    assert_success
    assert_output "0"

    unstub launchctl
}

@test "homebrew_dnsmasq_status returns failure if not running" {
    stub launchctl "exit 1"

    run homebrew_dnsmasq_status
    assert_success
    refute_output "0"

    unstub launchctl
}

@test "homebrew_dnsmasq_start notifies password is needed" {
    stub sudo \
        "-n true : exit 1" \
        "brew services start dnsmasq : exit 0"

    run homebrew_dnsmasq_start
    assert_success
    assert_output "Starting dnsmasq requires your password."

    unstub sudo
}

@test "homebrew_dnsmasq_start skips password notification" {
    stub sudo \
        "-n true : exit 0" \
        "brew services start dnsmasq : exit 0"

    run homebrew_dnsmasq_start
    assert_success
    refute_output

    unstub sudo
}

@test "homebrew_dnsmasq_stop notifies password is needed" {
    stub sudo \
        "-n true : exit 1" \
        "brew services stop dnsmasq : exit 0"

    run homebrew_dnsmasq_stop
    assert_success
    assert_output "Stopping dnsmasq requires your password."

    unstub sudo
}

@test "homebrew_dnsmasq_stop skips password notification" {
    stub sudo \
        "-n true : exit 0" \
        "brew services stop dnsmasq : exit 0"

    run homebrew_dnsmasq_stop
    assert_success
    refute_output

    unstub sudo
}

@test "homebrew_dnsmasq_mgr failed without arguments" {
    run homebrew_dnsmasq_mgr
    assert_failure
}

@test "homebrew_dnsmasq_mgr failed with correct argument" {
    run homebrew_dnsmasq_mgr bad-option
    assert_failure
}

@test "homebrew_dnsmasq_mgr succeeds on no status change" {
    homebrew_dnsmasq_status() { echo "1"; }

    run homebrew_dnsmasq_mgr "stopped"
    assert_success
    refute_output

    homebrew_dnsmasq_status() { echo "0"; }

    run homebrew_dnsmasq_mgr "running"
    assert_success
    refute_output
}

@test "homebrew_dnsmasq_mgr stops when running" {
    homebrew_dnsmasq_status() { echo "0"; }
    homebrew_dnsmasq_stop() { echo "stop called" > "${TMPDIR}/stop_called"; }
    homebrew_dnsmasq_start() { echo "start called" > "${TMPDIR}/start_called"; }

    run homebrew_dnsmasq_mgr "stopped"
    assert_success
    assert_output "Stopping dnsmasq"
    assert_file_exists "${TMPDIR}/stop_called"
    assert_file_not_exists "${TMPDIR}/start_called"
}

@test "homebrew_dnsmasq_mgr starts when stopped" {
    homebrew_dnsmasq_status() { echo "1"; }
    homebrew_dnsmasq_stop() { echo "stop called" > "${TMPDIR}/stop_called"; }
    homebrew_dnsmasq_start() { echo "start called" > "${TMPDIR}/start_called"; }

    run homebrew_dnsmasq_mgr "running"
    assert_success
    assert_output "Starting dnsmasq"
    assert_file_exists "${TMPDIR}/start_called"
    assert_file_not_exists "${TMPDIR}/stop_called"
}

@test "docker_status returns success if running" {
    stub docker "info : exit 0"

    run docker_status
    assert_success
    assert_output "0"

    unstub docker
}

@test "docker_status returns failure if not running" {
    stub docker "info : exit 1"

    run docker_status
    assert_success
    assert_output "1"

    unstub docker
}

@test "larakit_status returns success if running" {
    stub docker "ps --format '{{.Names}}' : echo laradock-workspace-1"

    run larakit_status
    assert_success
    assert_output "0"

    unstub docker
}

@test "larakit_status returns failure if not running" {
    stub docker "ps --format '{{.Names}}' : echo other-container"

    run larakit_status
    assert_success
    assert_output "1"

    unstub docker
}

@test "larakit_start returns start status" {
    stub larakit \
        "up : exit 0" \
        "up : exit 1"

    run larakit_start
    assert_success

    run larakit_start
    assert_failure

    unstub larakit
}

@test "larakit_stop returns stop status" {
    stub larakit \
        "down : exit 0" \
        "down : exit 1"

    run larakit_stop
    assert_success

    run larakit_stop
    assert_failure

    unstub larakit
}

@test "larakit_mgr failed without arguments" {
    run larakit_mgr
    assert_failure
}

@test "larakit_mgr failed with correct argument" {
    run larakit_mgr bad-option
    assert_failure
}

@test "larakit_mgr succeeds on no status change" {
    larakit_status() { echo "1"; }

    run larakit_mgr "stopped"
    assert_success
    refute_output

    larakit_status() { echo "0"; }

    run larakit_mgr "running"
    assert_success
    refute_output
}

@test "larakit_mgr stops when running" {
    larakit_status() { echo "0"; }
    larakit_stop() { echo "stop called" > "${TMPDIR}/stop_called"; }
    larakkit_start() { echo "start called" > "${TMPDIR}/start_called"; }

    run larakit_mgr "stopped"
    assert_success
    assert_output "Stopping larakit"
    assert_file_exists "${TMPDIR}/stop_called"
    assert_file_not_exists "${TMPDIR}/start_called"
}

@test "larakit_mgr starts when stopped" {
    larakit_status() { echo "1"; }
    larakit_stop() { echo "stop called" > "${TMPDIR}/stop_called"; }
    larakit_start() { echo "start called" > "${TMPDIR}/start_called"; }

    run larakit_mgr "running"
    assert_success
    assert_output "Starting larakit"
    assert_file_exists "${TMPDIR}/start_called"
    assert_file_not_exists "${TMPDIR}/stop_called"
}

@test "status shows dnsmasq and larakit stopped" {
    stub launchctl "exit 1"
    stub docker \
        "info : echo 0" \
        "ps --format '{{.Names}}' : echo other-container"

    run status
    assert_success

    assert_line --index 0 --partial "dnsmasq stopped"
    assert_line --index 1 --partial "docker running"
    assert_line --index 2 --partial "larakit stopped"

    unstub launchctl
    unstub docker
}

@test "status shows dnsmasq and larakit running" {
    stub launchctl "exit 0"
    stub docker \
        "info : echo 0" \
        "ps --format '{{.Names}}' : echo laradock-workspace-1"

    run status
    assert_success

    assert_line --index 0 --partial "dnsmasq running"
    assert_line --index 1 --partial "docker running"
    assert_line --index 2 --partial "larakit running"

    unstub launchctl
    unstub docker
}

@test "start_herd_environment calls service managers" {
    homebrew_dnsmasq_mgr() { echo "dnsmasq mgr called" > "${TMPDIR}/dnsmasq_${1:-}"; }
    larakit_mgr() { echo "larakit mgr called" > "${TMPDIR}/larakit_${1:-}"; }

    run start_herd_environment
    assert_success

    assert_file_exists "${TMPDIR}/dnsmasq_stopped"
    assert_file_exists "${TMPDIR}/larakit_stopped"
}

@test "start_larakit_environment calls service managers" {
    homebrew_dnsmasq_mgr() { echo "dnsmasq mgr called" > "${TMPDIR}/dnsmasq_${1:-}"; }
    docker_status() { echo "0"; }
    logmsg() { echo "logmsg called" > "${TMPDIR}/logmsg_called"; }
    larakit_mgr() { echo "larakit mgr called" > "${TMPDIR}/larakit_${1:-}"; }

    run start_larakit_environment
    assert_success

    assert_file_exists "${TMPDIR}/dnsmasq_running"
    assert_file_not_exists "$TMPDIR}/logmsg_called"
    assert_file_exists "${TMPDIR}/larakit_running"
}

@test "start_larakit_environment logs message if docker not running" {
    homebrew_dnsmasq_mgr() { echo "dnsmasq mgr called" > "${TMPDIR}/dnsmasq_${1:-}"; }
    docker_status() { echo "1"; }
    logmsg() { echo "logmsg called" > "${TMPDIR}/logmsg_called"; exit 1; }
    larakit_mgr() { echo "larakit mgr called" > "${TMPDIR}/larakit_${1:-}"; }

    run start_larakit_environment
    assert_failure

    assert_file_exists "${TMPDIR}/dnsmasq_running"
    assert_file_exists "${TMPDIR}/logmsg_called"
    assert_file_not_exists "${TMPDIR}/larakit_running"
}

@test "stop_all_environments calls service managers" {
    homebrew_dnsmasq_mgr() { echo "dnsmasq mgr called" > "${TMPDIR}/dnsmasq_${1:-}"; }
    larakit_mgr() { echo "larakit mgr called" > "${TMPDIR}/larakit_${1:-}"; }

    run stop_all_environments
    assert_success

    assert_file_exists "${TMPDIR}/dnsmasq_stopped"
    assert_file_exists "${TMPDIR}/larakit_stopped"
}
