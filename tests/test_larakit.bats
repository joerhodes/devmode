setup() {
    load "common_setup"
    _common_setup

    load "${DEVMODE_LIB}/larakit.zsh"
}

@test "larakit_status returns success if running" {
    stub docker "ps --format '{{.Names}}' : echo laradock-workspace-1"

    run larakit_status
    assert_success
}

@test "larakit_status returns failure if not running" {
    stub docker "ps --format '{{.Names}}' : echo other-container"

    run larakit_status
    assert_failure
}

@test "larakit_start returns success" {
    stub larakit "up  : exit 0"

    run larakit_start
    assert_success
}

@test "larakit_start returns failure" {
    stub larakit "up : exit 1"

    run larakit_start
    assert_failure
}

@test "larakit_stop returns success" {
    stub larakit "down  : exit 0"

    run larakit_stop
    assert_success
}

@test "larakit_stop returns failure" {
    stub larakit "down : exit 1"

    run larakit_stop
    assert_failure
}
