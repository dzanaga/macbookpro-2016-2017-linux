#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config; require_root "$@"; setup_logging; require_omarchy

main() {
  local user sudoers_file content headers
  user="$(setup_user)"; [ -n "$user" ] || die "Could not determine setup user"
  headers="$(kernel_headers_package)"
  log "Installing Omarchy/Arch prerequisites"
  pacman_install base-devel git curl wget ca-certificates dkms "$headers" iw usbutils
  if is_enabled PASSWORDLESS_SUDO; then
    [ "$SUDOERS_MODE" = full-user-nopasswd ] || die "Unsupported SUDOERS_MODE=$SUDOERS_MODE"
    sudoers_file="/etc/sudoers.d/90-mbp13-linux-setup-$user"
    content="$user ALL=(ALL:ALL) NOPASSWD: ALL
"
    write_file_if_changed "$sudoers_file" 0440 "$content"
    [ "$DRY_RUN" = 1 ] || visudo -cf "$sudoers_file"
  else
    log "Skipping passwordless sudo"
  fi
}
main "$@"
