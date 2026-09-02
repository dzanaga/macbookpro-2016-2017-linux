#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config; require_root "$@"; setup_logging; require_omarchy
SLEEP_CONF=/etc/systemd/sleep.conf.d/10-mbp13-suspend.conf
HOOK=/usr/lib/systemd/system-sleep/mbp13-suspend

main() {
  local conf hook
  case "$SUSPEND_MEMORY_SLEEP" in s2idle|deep) ;; *) die "SUSPEND_MEMORY_SLEEP must be s2idle or deep";; esac
  conf="# Managed by mbp13-linux-setup.
[Sleep]
SuspendState=mem
MemorySleepMode=$SUSPEND_MEMORY_SLEEP
"
  hook="#!/usr/bin/env bash
set -u
mode='$SUSPEND_MEMORY_SLEEP'
case \"\${1:-}:\${2:-}\" in
  pre:suspend|pre:hybrid-sleep|pre:suspend-then-hibernate)
    [ -w /sys/power/mem_sleep ] && grep -qw \"\$mode\" /sys/power/mem_sleep && printf '%s' \"\$mode\" >/sys/power/mem_sleep || true
    find /sys/devices -name d3cold_allowed -exec sh -c 'for f do printf 0 >\"\$f\" 2>/dev/null || true; done' sh {} +
    ;;
  post:suspend|post:hybrid-sleep|post:suspend-then-hibernate)
    [ -x /usr/local/sbin/mbp13-usbc-power ] && /usr/local/sbin/mbp13-usbc-power >/dev/null 2>&1 || true
    ;;
esac
"
  write_file_if_changed "$SLEEP_CONF" 0644 "$conf"; write_file_if_changed "$HOOK" 0755 "$hook"
  if [ -r /sys/power/mem_sleep ] && grep -qw "$SUSPEND_MEMORY_SLEEP" /sys/power/mem_sleep; then run sh -c 'printf "%s" "$1" > /sys/power/mem_sleep' sh "$SUSPEND_MEMORY_SLEEP"; else warn "$SUSPEND_MEMORY_SLEEP is not supported by this kernel"; fi
}
main "$@"
