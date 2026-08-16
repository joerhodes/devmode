setup() {
    load "common_setup"
    _common_setup

    load "${DEVMODE_LIB}/dnsmasq.zsh"
}

@test "homebrew_dnsmasq_status_returns_success" {
    stub launchctl "exit 0"

    run homebrew_dnsmasq_status
    assert_success
}

@test "homebrew_dnsmasq_status_returns_failure" {
    stub launchctl "exit 1"

    run homebrew_dnsmasq_status
    assert_failure
}

@test "homebrew_dnsmasq_start_returns_success" {
    stub sudo "brew services start dnsmasq : exit 0"

    run homebrew_dnsmasq_start
    assert_success
}

@test "homebrew_dnsmasq_start_returns_failure" {
    stub sudo "brew services start dnsmasq : exit 1"

    run homebrew_dnsmasq_start
    assert_failure
}

@test "homebrew_dnsmasq_stop_returns_success" {
    stub sudo "brew services stop dnsmasq : exit 0"

    run homebrew_dnsmasq_stop
    assert_success
}

@test "homebrew_dnsmasq_stop_returns_failure" {
    stub sudo "brew services stop dnsmasq : exit 1"

    run homebrew_dnsmasq_stop
    assert_failure
}
