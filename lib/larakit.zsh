#==================================
# Library to help control Larakit
#==================================

[ -n "${DEVMODE_LARAKIT_LOADED:-}" ] && return
DEVMOD_LARAKIT_LOADED=1

larakit_status() {
    docker ps --format '{{.Names}}' | grep -q '^laradock-'
}

larakit_start() {
    larakit up > /dev/null 2>&1
}

larakit_stop() {
    larakit down > /dev/null 2>&1
}
