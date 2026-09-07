#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config; require_root "$@"; setup_logging
section() { printf '\n== %s ==\n' "$1"; }
module_path() { modinfo -n "$1" 2>/dev/null || printf missing; }

main() {
  local path iface
  section status
  if [ "$DRY_RUN" = 1 ]; then printf 'Dry run; status was printed during module execution\n'; elif [ -f "$REPORT_FILE" ]; then cat "$REPORT_FILE"; else printf 'No module status file found\n'; fi
  section system; printf 'model: %s\nkernel: %s\n' "$(model_name)" "$(uname -r)"; (. /etc/os-release; printf 'os: %s\n' "${PRETTY_NAME:-unknown}")
  section wifi
  for path in /sys/class/net/*; do [ -d "$path/wireless" ] || continue; iface="$(basename "$path")"; printf '%s mac=%s\n' "$iface" "$(read_sysfs "$path/address")"; done
  ls -l /usr/lib/firmware/brcm/brcmfmac43602-pcie*.txt 2>/dev/null || true
  section sound; printf 'snd_hda_codec_cs8409: %s\n' "$(module_path snd_hda_codec_cs8409)"; dkms status 2>/dev/null | grep -i snd_hda_macbookpro || true
  section 'touchbar and camera'
  for module in apple_ibridge apple_ib_tb apple_ib_als uvcvideo; do printf '%s: %s\n' "$module" "$(module_path "$module")"; done
  dkms status 2>/dev/null | grep -E 'appleibridge|macbook12-spi-driver' || true
  systemctl is-active touchbar.service 2>/dev/null | sed 's/^/touchbar-service: /' || true
  command_exists lsusb && lsusb | grep -Ei '05ac:(8600|1281|8102|8302)' || true
  find /sys/class/video4linux -maxdepth 1 -mindepth 1 -printf '%f ' 2>/dev/null || true; printf '\n'
  section 'usbc power'; [ -x /usr/local/sbin/mbp13-usbc-power ] && /usr/local/sbin/mbp13-usbc-power || printf 'helper: missing\n'; systemctl is-active mbp13-usbc-power.service 2>/dev/null || true
  section suspend; printf 'mem_sleep: '; cat /sys/power/mem_sleep 2>/dev/null || true
  [ -f /etc/systemd/sleep.conf.d/10-mbp13-suspend.conf ] && printf 'sleep drop-in: present\n' || printf 'sleep drop-in: missing\n'
  section reboot; if [ -s "$NEEDS_REBOOT_FILE" ]; then printf 'recommended: yes\n'; sort -u "$NEEDS_REBOOT_FILE"; else printf 'recommended: no explicit reboot marker\n'; fi
}
main "$@"
