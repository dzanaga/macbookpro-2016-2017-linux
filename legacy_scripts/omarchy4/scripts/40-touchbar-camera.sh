#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config; require_root "$@"; setup_logging; require_omarchy

DRIVER_NAME=appleibridge
DRIVER_VERSION=0.1
DKMS_SOURCE=/usr/src/appleibridge-0.1
SERVICE=/etc/systemd/system/touchbar.service
HELPER=/usr/local/sbin/touchbar-enable.sh
MODULES_LOAD_FILE=/etc/modules-load.d/apple-touchbar-camera.conf
MODPROBE_FILE=/etc/modprobe.d/apple-t1-touchbar.conf

remove_obsolete_omarchy_driver() {
  if pacman -Q macbook12-spi-driver-dkms >/dev/null 2>&1; then
    log "Removing Omarchy's obsolete, unbuilt macbook12-spi-driver DKMS package"
    run dkms remove -m macbook12-spi-driver -v 0+git.315 --all || true
    run pacman -R --noconfirm macbook12-spi-driver-dkms
  fi
}

install_driver_source() {
  local repo file
  repo="$WORK_DIR/omarchy-macbookpro-t1"
  clone_or_update_repo https://github.com/nohzafk/omarchy-macbookpro-t1.git "$repo"
  ensure_dir "$DKMS_SOURCE"
  for file in apple-ib-als.c apple-ib-tb.c apple-ibridge.c apple-ibridge.h Makefile dkms.conf; do
    [ "$DRY_RUN" = 1 ] || [ -f "$repo/drivers/appleibridge/$file" ] || die "Driver source is missing $file"
    run install -m 0644 "$repo/drivers/appleibridge/$file" "$DKMS_SOURCE/$file"
  done
  run dkms remove -m "$DRIVER_NAME" -v "$DRIVER_VERSION" --all || true
  run dkms add -m "$DRIVER_NAME" -v "$DRIVER_VERSION"
  run dkms build -m "$DRIVER_NAME" -v "$DRIVER_VERSION" -k "$(uname -r)"
  run dkms install -m "$DRIVER_NAME" -v "$DRIVER_VERSION" -k "$(uname -r)"
  run depmod -a
  run install -m 0755 "$repo/systemd/touchbar-enable.sh" "$HELPER"
  run install -m 0644 "$repo/systemd/touchbar.service" "$SERVICE"
}

main() {
  local headers modules_load modprobe_conf
  headers="$(kernel_headers_package)"
  pacman_install base-devel git dkms "$headers" zstd usbutils
  if [ "$DRY_RUN" != 1 ] && [ ! -e "/usr/lib/modules/$(uname -r)/build/Makefile" ]; then
    die "Headers do not match running kernel $(uname -r). Reboot into the upgraded kernel, then rerun install.sh"
  fi
  if command_exists lsusb && lsusb | grep -qi '05ac:1281'; then
    die "T1 is in recovery mode; repair bridgeOS/EFI Apple payload from macOS/OCLP"
  fi
  remove_obsolete_omarchy_driver
  install_driver_source
  modprobe_conf="# T1 modules must load late via touchbar.service.
blacklist apple_ibridge
blacklist apple_ib_tb
blacklist apple_ib_als
"
  modules_load="# T1 Touch Bar modules deliberately load late via touchbar.service.
"
  write_file_if_changed "$MODPROBE_FILE" 0644 "$modprobe_conf"
  write_file_if_changed "$MODULES_LOAD_FILE" 0644 "$modules_load"
  bash "$MBP13_ROOT/scripts/41-touchbar-settings.sh"
  run systemctl daemon-reload
  run systemctl enable touchbar.service
  update_initramfs
  mark_reboot_needed "T1 Touch Bar DKMS driver installed"
  log "Touch Bar driver installed; reboot before judging whether it bound successfully"
}
main "$@"
