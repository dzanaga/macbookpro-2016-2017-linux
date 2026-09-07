#!/usr/bin/env bash
set -Eeuo pipefail
MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$MBP13_ROOT/scripts/00-lib.sh"; load_config; require_root "$@"; setup_logging; require_omarchy

main() {
  local repo headers
  headers="$(kernel_headers_package)"
  log "Installing Cirrus CS8409 MacBook audio driver for $(uname -r)"
  pacman_install base-devel git patch wget dkms "$headers"
  if [ "$DRY_RUN" != 1 ] && [ ! -e "/usr/lib/modules/$(uname -r)/build/Makefile" ]; then
    die "Matching kernel headers are unavailable after installing $headers"
  fi
  repo="$WORK_DIR/snd_hda_macbookpro"
  clone_or_update_repo https://github.com/davidjo/snd_hda_macbookpro.git "$repo"
  run_in_dir "$repo" ./install.cirrus.driver.sh -i
  run depmod -a; update_initramfs; mark_reboot_needed "sound driver installed"
}
main "$@"
