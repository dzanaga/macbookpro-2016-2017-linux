#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config; require_root "$@"; setup_logging; require_omarchy

SETTINGS_FILE=/etc/default/mbp13-touchbar
APPLY_HELPER=/usr/local/sbin/mbp13-touchbar-settings
SERVICE_DROPIN=/etc/systemd/system/touchbar.service.d/10-settings.conf

validate_integer_at_least_minus_two() {
  [[ "$2" =~ ^-?[0-9]+$ ]] || die "$1 must be an integer"
  [ "$2" -ge -2 ] || die "$1 must be -2 or greater"
}

main() {
  local settings helper dropin
  case "$TOUCHBAR_FNMODE" in 0|1|2|3) ;; *) die "TOUCHBAR_FNMODE must be 0, 1, 2, or 3";; esac
  validate_integer_at_least_minus_two TOUCHBAR_IDLE_TIMEOUT "$TOUCHBAR_IDLE_TIMEOUT"
  validate_integer_at_least_minus_two TOUCHBAR_DIM_TIMEOUT "$TOUCHBAR_DIM_TIMEOUT"

  settings="# Managed by mbp13-linux-setup.
TOUCHBAR_FNMODE=$TOUCHBAR_FNMODE
TOUCHBAR_IDLE_TIMEOUT=$TOUCHBAR_IDLE_TIMEOUT
TOUCHBAR_DIM_TIMEOUT=$TOUCHBAR_DIM_TIMEOUT
"
  helper='#!/usr/bin/env bash
set -Eeuo pipefail
source /etc/default/mbp13-touchbar
for device in /sys/bus/hid/devices/0003:05AC:8600.*; do
  [ -e "$device" ] || continue
  real="$(readlink -f "$device")"
  [ -w "$real/fnmode" ] || continue
  printf "%s" "$TOUCHBAR_IDLE_TIMEOUT" >"$real/idle_timeout"
  printf "%s" "$TOUCHBAR_DIM_TIMEOUT" >"$real/dim_timeout"
  printf "%s" "$TOUCHBAR_FNMODE" >"$real/fnmode"
  printf "Touch Bar settings: fnmode=%s idle=%s dim=%s\n" \
    "$(cat "$real/fnmode")" "$(cat "$real/idle_timeout")" "$(cat "$real/dim_timeout")"
  exit 0
done
printf "Touch Bar sysfs controls were not found\n" >&2
exit 1
'
  dropin="[Service]
ExecStartPost=$APPLY_HELPER
"
  write_file_if_changed "$SETTINGS_FILE" 0644 "$settings"
  write_file_if_changed "$APPLY_HELPER" 0755 "$helper"
  write_file_if_changed "$SERVICE_DROPIN" 0644 "$dropin"
  run systemctl daemon-reload
  if systemctl is-active --quiet touchbar.service; then run "$APPLY_HELPER"; else log "Settings will apply when touchbar.service next starts"; fi
}
main "$@"
