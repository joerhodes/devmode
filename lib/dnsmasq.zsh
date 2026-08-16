#=====================================================
# Library to help control Homebrew's dnsmasq service
#=====================================================

[ -n "${DEVMODE_DNSMASQ_LOADED:-}" ] && return
DEVMODE_DNSMASQ_LOADED=1

homebrew_dnsmasq_status() {
    launchctl print system/homebrew.mxcl.dnsmasq > /dev/null 2>&1
}

homebrew_dnsmasq_start() {
    sudo brew services start dnsmasq
}

homebrew_dnsmasq_stop() {
    sudo brew services stop dnsmasq
}
