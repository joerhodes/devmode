setup() {
    load "common_setup"
    _common_setup

    load "${DEVMODE_LIB}/dnsmasq.zsh"
}

@test "homebrew_dnsmasq_status returns success if running" {
    stub launchctl "exit 0"

    run homebrew_dnsmasq_status
    assert_success
}

@test "homebrew_dnsmasq_status returns failure if not running" {
    stub launchctl "exit 1"

    run homebrew_dnsmasq_status
    assert_failure
}

@test "homebrew_dnsmasq_start returns success" {
    stub sudo "brew services start dnsmasq : exit 0"

    run homebrew_dnsmasq_start
    assert_success
}

@test "homebrew_dnsmasq_start returns failure" {
    stub sudo "brew services start dnsmasq : exit 1"

    run homebrew_dnsmasq_start
    assert_failure
}

@test "homebrew_dnsmasq_stop returns success" {
    stub sudo "brew services stop dnsmasq : exit 0"

    run homebrew_dnsmasq_stop
    assert_success
}

@test "homebrew_dnsmasq_stop returns failure" {
    stub sudo "brew services stop dnsmasq : exit 1"

    run homebrew_dnsmasq_stop
    assert_failure
}
