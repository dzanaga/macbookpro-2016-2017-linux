#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config

find_wifi_iface() {
  local path iface module driver
  for path in /sys/class/net/*; do
    iface="$(basename "$path")"; [ -d "$path/wireless" ] || continue
    module=""; driver=""
    [ -L "$path/device/driver/module" ] && module="$(basename "$(readlink "$path/device/driver/module")")"
    [ -L "$path/device/driver" ] && driver="$(basename "$(readlink "$path/device/driver")")"
    if [ "$module" = brcmfmac ] || [ "$driver" = brcmfmac ]; then printf '%s\n' "$iface"; return; fi
  done
  for path in /sys/class/net/*; do [ -d "$path/wireless" ] && { basename "$path"; return; }; done
  return 1
}

main() {
  local iface mac template firmware_dir rendered model target targets
  iface="$(find_wifi_iface)" || die "Could not find a wireless Broadcom/brcmfmac interface"
  if [ "${1:-}" = --print-mac ]; then read_sysfs "/sys/class/net/$iface/address"; return; fi
  require_root "$@"; setup_logging; require_omarchy
  mac="$(read_sysfs "/sys/class/net/$iface/address")"; [ -n "$mac" ] || die "Could not read MAC address for $iface"
  template="$MBP13_ROOT/$WIFI_TEMPLATE"; [ -r "$template" ] || die "Missing Wi-Fi template: $template"
  rendered="$(sed -e "s/{{WIFI_MACADDR}}/$mac/g" -e "s/{{WIFI_COUNTRY}}/$WIFI_COUNTRY/g" "$template")"
  firmware_dir=/usr/lib/firmware/brcm; ensure_dir "$firmware_dir"; model="$(model_name)"
  targets=("$firmware_dir/brcmfmac43602-pcie.txt")
  [ -n "$model" ] && targets+=("$firmware_dir/brcmfmac43602-pcie.Apple Inc.-$model.txt")
  log "Installing BCM43602 NVRAM for $iface ($mac)"
  for target in "${targets[@]}"; do write_file_if_changed "$target" 0644 "$rendered"; done
  command_exists iw && run iw reg set "$WIFI_COUNTRY" || warn "Could not set live regulatory domain"
  # Use Omarchy's root-only, non-interactive Limine/mkinitcpio integration.
  update_initramfs
  mark_reboot_needed "Wi-Fi firmware installed"
}
main "$@"
