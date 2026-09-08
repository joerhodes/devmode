setup() {
    load "common_setup"
    _common_setup

    TMPDIR="$(mktemp -d)"

    DEVMODE_CONFIG_DIR="$TMPDIR"

    load "${DEVMODE_BIN}/devmode"
}

@test "usage displays help message" {
    run usage
    assert_success
    assert_line --index 0 "Usage: devmode <environment>   e.g. devmode herd | devmode larakit"
    assert_line --index 1 "       devmode list"
    assert_line --index 2 "       devmode status"
    assert_line --index 3 "       devmode stop"
}

@test "display status line displays up status" {
    run display_status_line "test" 0
    assert_success
    assert_output --partial "test up"
}

@test "display status line displays down status" {
    run display_status_line "test" 1
    assert_success
    assert_output --partial "test down"
}

@test "resolve_compose_file resolves directory to docker-compose.yml" {
    mkdir -p "${TMPDIR}/project"
    run resolve_compose_file "${TMPDIR}/project"
    assert_success
    assert_output "${TMPDIR}/project/docker-compose.yml"
}

@test "devmode::brew_status displays up status" {
    stub launchctl "exit 0"

    run devmode::brew_status "test"
    assert_success
    assert_output --partial "test up"

    unstub launchctl
}

@test "devmode::brew_status displays down status" {
    stub launchctl "exit 1"

    run devmode::brew_status "test"
    assert_failure
    assert_output --partial "test down"

    unstub launchctl
}

@test "devmode::brew_start succeeds if service is already running" {
    stub launchctl "exit 0"

    run devmode::brew_start "test"
    assert_success

    unstub launchctl
}

@test "devmode::brew_start starts service" {
    stub launchctl "exit 1"
    stub sudo \
        "exit 0" \
        "exit 0"

    run devmode::brew_start "test"
    assert_success

    unstub launchctl
    unstub sudo
}

@test "devmode::brew_stop succeeds if service is already stopped" {
    stub launchctl "exit 1"

    run devmode::brew_stop "test"
    assert_success

    unstub launchctl
}

@test "devmode::brew_stop stops service" {
    stub launchctl "exit 0"
    stub sudo \
        "exit 0" \
        "exit 0"

    run devmode::brew_stop "test"
    assert_success

    unstub launchctl
    unstub sudo
}

@test "devmode::app_status displays up status" {
    stub pgrep "exit 0"

    run devmode::app_status "test"
    assert_success
    assert_output --partial "test up"

    unstub pgrep
}

@test "devmode::app_status displays down status" {
    stub pgrep "exit 1"

    run devmode::app_status "test"
    assert_failure
    assert_output --partial "test down"

    unstub pgrep
}

@test "devmode::app_launch succeeds if app already running" {
    stub pgrep "exit 0"

    run devmode::app_launch "test"
    assert_success

    unstub pgrep
}

@test "devmode::app_launch launches app" {
    stub pgrep "exit 1"
    stub open "exit 0"

    run devmode::app_launch "test"
    assert_success

    unstub pgrep
    unstub open
}

@test "devmode::app_quit exits if app not running" {
    stub pgrep "exit 1"

    run devmode::app_quit "test"
    assert_success

    unstub pgrep
}

@test "devmode::app_quit quits app" {
    stub pgrep "exit 0"
    stub osascript "exit 0"

    run devmode::app_quit "test"
    assert_success

    unstub pgrep
    unstub osascript
}


@test "devmode::docker_desktop_status displays up status" {
    stub docker "exit 0"

    run devmode::docker_desktop_status
    assert_success
    assert_output --partial "Docker Desktop up"

    unstub docker
}

@test "devmode::docker_desktop_status displays down status" {
    stub docker "exit 1"

    run devmode::docker_desktop_status
    assert_failure
    assert_output --partial "Docker Desktop down"

    unstub docker
}

@test "devmode::docker_desktop_launch succeeds when Docker Desktop is already running" {
    stub docker "info : exit 0"

    run devmode::docker_desktop_launch
    assert_success

    unstub docker
}

@test "devmode::docker_desktop_launch starts Docker Desktop" {
    stub docker \
        "info : exit 1" \
        "desktop start : exit 0"

    run devmode::docker_desktop_launch
    assert_success

    unstub docker
}

@test "devmode::docker_desktop_quit succeeds when Docker Desktop is not running" {
    stub docker "info : exit 1"

    run devmode::docker_desktop_quit
    assert_success

    unstub docker
}

@test "devmode::docker_desktop_quit quits Docker Desktop" {
    stub docker \
        "info : exit 0" \
        "desktop stop : exit 0"

    run devmode::docker_desktop_quit
    assert_success

    unstub docker
}

@test "devmode::docker_status displays container is up" {
    stub docker \
        "exit 0" \
        "echo true"

    devmode::docker_desktop_status &> /dev/null
    run devmode::docker_status "test"
    assert_success
    assert_output --partial "test up"

    unstub docker
}

@test "devmode::docker_status displays container is down" {
    stub docker \
        "exit 0" \
        "echo error: no such object: test"

    devmode::docker_desktop_status &> /dev/null
    run devmode::docker_status "test"
    assert_failure
    assert_output --partial "test down"

    unstub docker
}

@test "devmode::docker_start succeeds when container is already running" {
    devmode::docker_desktop_launch() { return 0; }
    stub docker \
        "inspect -f '{{.State.Running}}' test : echo true"

    run devmode::docker_start "test"
    assert_success

    unstub docker
}

@test "devmode::docker_start starts container" {
    devmode::docker_desktop_launch() { return 0; }
    stub docker \
        "inspect -f '{{.State.Running}}' test  : echo false" \
        "start test : exit 0"

    run devmode::docker_start "test"
    assert_success

    unstub docker
}

@test "devmode::docker_stop succeeds when container is not running" {
    stub docker \
        "inspect -f '{{.State.Running}}' test  : echo false"

    run devmode::docker_stop "test"
    assert_success

    unstub docker
}

@test "devmode::docker_stop fails when container is running" {
    stub docker \
        "inspect -f '{{.State.Running}}' test  : echo true" \
        "stop test : exit 0"

    run devmode::docker_stop "test"
    assert_success

    unstub docker
}

# bats test_tags=bats:focus
@test "devmode::compose_status reports project is running" {
    display_status_line() { printf "%s %d\n" "$1" "$2"; }
    mkdir -p "${TMPDIR}/project"
    stub docker \
        "compose -f ${TMPDIR}/project/docker-compose.yml ps --status running -q : echo test"

    run devmode::compose_status "${TMPDIR}/project"
    assert_success
    assert_output "project 0"

    unstub docker
}

# bats test_tags=bats:focus
@test "devmode::compose_status reports project is not running" {
    display_status_line() { printf "%s %d\n" "$1" "$2"; }
    mkdir -p "${TMPDIR}/project"
    stub docker \
        "compose -f ${TMPDIR}/project/docker-compose.yml ps --status running -q : exit 0"

    run devmode::compose_status "${TMPDIR}/project"
    assert_failure
    assert_output "project 1"

    unstub docker
}

@test "devmode:compose_up succeeds if project running" {
    devmode::docker_desktop_launch() { return 0; }
    stub docker \
        "compose -f project/test.yml ps --status running -q : echo test"

    run devmode::compose_up "project/test.yml"
    assert_success

    unstub docker
}

@test "devmode:compose_up starts project if not running" {
    devmode::docker_desktop_launch() { return 0; }
    stub docker \
        "compose -f project/test.yml ps --status running -q : exit 0" \
        "compose -f project/test.yml up -d : exit 0"

    run devmode::compose_up "project/test.yml"
    assert_success

    unstub docker
}

@test "devmode:compose_down succeeds if project not running" {
    stub docker \
        "compose -f project/test.yml ps --status running -q : exit 0"

    run devmode::compose_down "project/test.yml"
    assert_success

    unstub docker
}

@test "devmode:compose_down stops project if not running" {
    stub docker \
        "compose -f project/test.yml ps --status running -q : echo test" \
        "compose -f project/test.yml down : exit 0"

    run devmode::compose_down "project/test.yml"
    assert_success

    unstub docker
}

@test "list_environments lists available environments" {
    touch "$DEVMODE_CONFIG_DIR/test1.conf"
    touch "$DEVMODE_CONFIG_DIR/test2.conf"
    run list_environments
    assert_success
    assert_output --partial "test1"
    assert_output --partial "test2"
}

@test "list_environments lists no environments" {
    run list_environments
    assert_success
    assert_output --partial ""
}

@test "display_environments lists available environments" {
    touch "$DEVMODE_CONFIG_DIR/test1.conf"
    touch "$DEVMODE_CONFIG_DIR/test2.conf"
    run display_environments
    assert_success
    assert_output --partial "test1"
    assert_output --partial "test2"
}

@test "display_environments shows no environments found" {
    run display_environments
    assert_failure
    assert_output --partial "No environments found in $DEVMODE_CONFIG_DIR"
}

@test "display_statuses shows no environments found" {
    run display_statuses
    assert_failure
    assert_output --partial "No environments found in $DEVMODE_CONFIG_DIR"
}

@test "display_statuses lists available statuses" {
    echo "
    devmode_status() {
        echo "test component up"
        return 0
    }
    " > "$DEVMODE_CONFIG_DIR/test.conf"

    run display_statuses
    assert_success
    assert_output --partial "test:"
    assert_output --partial "test component up"
}

@test "active_environments lists active environments" {
    echo "
    devmode_status() {
        echo "test component up"
        return 0
    }
    " > "$DEVMODE_CONFIG_DIR/test.conf"
    run active_environments
    assert_success
    assert_output --partial "test"
}

@test "active_environments lists multiple active environments" {
    echo "
    devmode_status() {
        echo "test component up"
        return 0
    }
    " > "$DEVMODE_CONFIG_DIR/test.conf"
    echo "
    devmode_status() {
        echo "test2 component up"
        return 0
    }
    " > "$DEVMODE_CONFIG_DIR/test2.conf"
    run active_environments
    assert_success
    assert_output --partial "test"
    assert_output --partial "test2"
}

@test "active_environments lists no active environments" {
    echo "
    devmode_status() {
        echo "test component down"
        return 1
    }
    " > "$DEVMODE_CONFIG_DIR/test.conf"
    run active_environments
    assert_success
    assert_output ""
}

@test "stop_environments reports no active environments" {
    echo "
    devmode_status() {
        echo "test component down"
        return 1
    }
    " > "$DEVMODE_CONFIG_DIR/test.conf"
    run stop_environments
    assert_success
    assert_output "No environments currently active."
}

@test "stop_environments stops active environments" {
    echo "
    devmode_status() {
        echo "test component up"
        return 0
    }
    devmode_down() {
        return 0
    }
    " > "$DEVMODE_CONFIG_DIR/test.conf"
    run stop_environments
    assert_success
    assert_output "Stopping test..."
}

@test "stop_environments warns when dev_down fails" {
    echo "
    devmode_status() {
        echo "test component up"
        return 0
    }
    devmode_down() {
        return 1
    }
    " > "$DEVMODE_CONFIG_DIR/test.conf"
    run stop_environments
    assert_failure
    assert_output --partial "Stopping test..."
    assert_output --partial "Warning: devmode_down for test did not exit cleanly."
}

@test "switch_environment short circuits when target is active" {
    active_environments() { printf "test\n"; }
    run switch_environment "test"
    assert_success
    assert_output "test is already active — nothing to do."
}

@test "switch_environment reports error when stopping environments fails" {
    stop_environments() { return 1; }
    run switch_environment "test"
    assert_failure
    assert_output --partial "Failed to stop currently active environment(s)"
    assert_output --partial "aborting switch to test."
}

@test "switch_environment stops environments and switches to target" {
    stop_environments() { return 0; }
    devmode_up() { return 0; }
    run switch_environment "test"
    assert_success
    assert_output --partial "Starting test..."
}

@test "switch_environment reports error when devmode_up fails" {
    stop_environments() { return 0; }
    devmode_up() { return 1; }
    run switch_environment "test"
    assert_failure
    assert_output --partial "Starting test..."
    assert_output --partial "devmode_up for test did not exit cleanly."
}
