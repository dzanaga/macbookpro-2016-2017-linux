#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config; require_root "$@"; setup_logging; require_omarchy
HELPER=/usr/local/sbin/mbp13-usbc-power
SERVICE=/etc/systemd/system/mbp13-usbc-power.service
SLEEP_HOOK=/usr/lib/systemd/system-sleep/mbp13-usbc-power

main() {
  local helper service hook
  helper="#!/usr/bin/env bash
set -u
disable_d3cold='$USBC_POWER_DISABLE_D3COLD'; keep_nhi='$USBC_POWER_KEEP_NHI'
enabled() { case \"\${1:-0}\" in 1|yes|true|on|Y|y|TRUE|YES|ON) return 0;; *) return 1;; esac; }
managed() {
  [ \"\$(cat \"\$1/vendor\" 2>/dev/null)\" = 0x8086 ] || return 1
  case \"\$(cat \"\$1/device\" 2>/dev/null)\" in 0x15d4) return 0;; 0x15d2) enabled \"\$keep_nhi\";; *) return 1;; esac
}
found=0
for dev in /sys/bus/pci/devices/*; do
  managed \"\$dev\" || continue; found=1
  [ -w \"\$dev/power/control\" ] && printf on >\"\$dev/power/control\"
  if enabled \"\$disable_d3cold\" && [ -w \"\$dev/d3cold_allowed\" ]; then printf 0 >\"\$dev/d3cold_allowed\"; fi
  printf '%s control=%s runtime=%s d3cold=%s\\n' \"\$(basename \"\$dev\")\" \"\$(cat \"\$dev/power/control\" 2>/dev/null || printf unknown)\" \"\$(cat \"\$dev/power/runtime_status\" 2>/dev/null || printf unknown)\" \"\$(cat \"\$dev/d3cold_allowed\" 2>/dev/null || printf n/a)\"
done
[ \"\$found\" -eq 1 ] || { printf 'No matching Alpine Ridge controllers found\\n' >&2; exit 1; }
"
  service="[Unit]
Description=Keep MacBookPro13 USB-C controllers awake
After=sysinit.target
[Service]
Type=oneshot
ExecStart=$HELPER
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
"
  hook="#!/usr/bin/env bash
case \"\${1:-}:\${2:-}\" in pre:suspend|post:suspend|pre:hybrid-sleep|post:hybrid-sleep|pre:suspend-then-hibernate|post:suspend-then-hibernate) '$HELPER' >/dev/null 2>&1 || true;; esac
"
  write_file_if_changed "$HELPER" 0755 "$helper"; write_file_if_changed "$SERVICE" 0644 "$service"; write_file_if_changed "$SLEEP_HOOK" 0755 "$hook"
  run systemctl daemon-reload; run systemctl enable --now mbp13-usbc-power.service
}
main "$@"
