#!/usr/bin/env bash

MBP13_ROOT="${MBP13_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG_FILE="${CONFIG_FILE:-$MBP13_ROOT/config.env}"

RUN_MISC="${RUN_MISC:-1}"; RUN_WIFI="${RUN_WIFI:-1}"; RUN_SOUND="${RUN_SOUND:-1}"
RUN_TOUCHBAR_CAMERA="${RUN_TOUCHBAR_CAMERA:-1}"; RUN_USBC_POWER="${RUN_USBC_POWER:-1}"; RUN_SUSPEND="${RUN_SUSPEND:-1}"
PASSWORDLESS_SUDO="${PASSWORDLESS_SUDO:-1}"; SUDOERS_MODE="${SUDOERS_MODE:-full-user-nopasswd}"
WIFI_COUNTRY="${WIFI_COUNTRY:-BE}"; WIFI_TEMPLATE="${WIFI_TEMPLATE:-../ubuntu-26.04/assets/wifi/brcmfmac43602-pcie.template.txt}"
TOUCHBAR_FNMODE="${TOUCHBAR_FNMODE:-0}"; TOUCHBAR_IDLE_TIMEOUT="${TOUCHBAR_IDLE_TIMEOUT:--1}"; TOUCHBAR_DIM_TIMEOUT="${TOUCHBAR_DIM_TIMEOUT:--1}"
USBC_POWER_DISABLE_D3COLD="${USBC_POWER_DISABLE_D3COLD:-1}"; USBC_POWER_KEEP_NHI="${USBC_POWER_KEEP_NHI:-1}"
SUSPEND_MEMORY_SLEEP="${SUSPEND_MEMORY_SLEEP:-s2idle}"
WORK_DIR="${WORK_DIR:-/var/lib/mbp13-linux-setup/omarchy-4}"; BACKUP_DIR="${BACKUP_DIR:-/var/backups/mbp13-linux-setup/omarchy-4}"
LOG_FILE="${LOG_FILE:-/var/log/mbp13-omarchy-setup.log}"; REPORT_FILE="${REPORT_FILE:-/run/mbp13-omarchy-setup.report}"
DRY_RUN="${DRY_RUN:-0}"; NEEDS_REBOOT_FILE="${NEEDS_REBOOT_FILE:-/run/mbp13-omarchy-setup.needs-reboot}"

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn() { log "WARN: $*" >&2; }
die() { log "ERROR: $*" >&2; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }
load_config() { if [ -f "$CONFIG_FILE" ]; then source "$CONFIG_FILE"; fi; }
is_enabled() { case "${!1:-0}" in 1|yes|true|on|Y|y|TRUE|YES|ON) return 0;; *) return 1;; esac; }

require_omarchy() {
  [ -r /etc/os-release ] || die "Cannot identify the operating system"
  local id id_like build_id
  id="$(. /etc/os-release; printf '%s' "${ID:-}")"
  id_like="$(. /etc/os-release; printf '%s' "${ID_LIKE:-}")"
  build_id="$(. /etc/os-release; printf '%s' "${BUILD_ID:-${VERSION_ID:-}}")"
  [ "$id" = omarchy ] || die "This installer requires Omarchy; detected ${id:-unknown}"
  case "$id_like" in *arch*) ;; *) die "Omarchy installation is not Arch-based";; esac
  case "$build_id" in 4|4.*) ;; *) warn "Designed for Omarchy 4; detected ${build_id:-unknown}";; esac
}

setup_logging() {
  [ "${MBP13_LOGGING_ACTIVE:-0}" = 1 ] && return 0
  export MBP13_LOGGING_ACTIVE=1
  if [ "$DRY_RUN" = 1 ]; then
    log "DRY_RUN=1; mutating actions will be printed only"
    return 0
  fi
  if ! : 2>/dev/null >>"$LOG_FILE"; then warn "Cannot write $LOG_FILE; using console only"; return; fi
  exec > >(tee -a "$LOG_FILE") 2>&1
}

require_root() {
  [ "$(id -u)" -eq 0 ] && return
  [ "$DRY_RUN" = 1 ] && { log "DRY_RUN=1; not escalating to root"; return; }
  exec sudo \
    MBP13_ROOT="$MBP13_ROOT" CONFIG_FILE="$CONFIG_FILE" DRY_RUN="$DRY_RUN" SETUP_USER="${SETUP_USER:-}" \
    RUN_MISC="$RUN_MISC" RUN_WIFI="$RUN_WIFI" RUN_SOUND="$RUN_SOUND" RUN_TOUCHBAR_CAMERA="$RUN_TOUCHBAR_CAMERA" \
    RUN_USBC_POWER="$RUN_USBC_POWER" RUN_SUSPEND="$RUN_SUSPEND" PASSWORDLESS_SUDO="$PASSWORDLESS_SUDO" \
    SUDOERS_MODE="$SUDOERS_MODE" WIFI_COUNTRY="$WIFI_COUNTRY" WIFI_TEMPLATE="$WIFI_TEMPLATE" \
    TOUCHBAR_FNMODE="$TOUCHBAR_FNMODE" TOUCHBAR_IDLE_TIMEOUT="$TOUCHBAR_IDLE_TIMEOUT" TOUCHBAR_DIM_TIMEOUT="$TOUCHBAR_DIM_TIMEOUT" \
    USBC_POWER_DISABLE_D3COLD="$USBC_POWER_DISABLE_D3COLD" USBC_POWER_KEEP_NHI="$USBC_POWER_KEEP_NHI" \
    SUSPEND_MEMORY_SLEEP="$SUSPEND_MEMORY_SLEEP" WORK_DIR="$WORK_DIR" BACKUP_DIR="$BACKUP_DIR" LOG_FILE="$LOG_FILE" \
    bash "$0" "$@"
}

run() { if [ "$DRY_RUN" = 1 ]; then printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi; }
run_in_dir() { local dir="$1"; shift; if [ "$DRY_RUN" = 1 ]; then printf '[dry-run] cd %q &&' "$dir"; printf ' %q' "$@"; printf '\n'; else (cd "$dir" && "$@"); fi; }
ensure_dir() { [ "$DRY_RUN" = 1 ] && log "[dry-run] mkdir -p $1" || mkdir -p "$1"; }
backup_file() { [ -e "$1" ] || return 0; ensure_dir "$BACKUP_DIR"; run cp -a "$1" "$BACKUP_DIR/$(basename "$1").$(date '+%Y%m%d-%H%M%S')"; }

write_file_if_changed() {
  local path="$1" mode="$2" content="$3" tmp
  [ "$DRY_RUN" = 1 ] && { log "[dry-run] write $path mode $mode"; return; }
  tmp="$(mktemp)"; printf '%s' "$content" >"$tmp"
  if [ -f "$path" ] && cmp -s "$tmp" "$path"; then chmod "$mode" "$path"; chown root:root "$path"; rm -f "$tmp"; return; fi
  backup_file "$path"; install -o root -g root -m "$mode" -D "$tmp" "$path"; rm -f "$tmp"
}

append_report() { [ "$DRY_RUN" = 1 ] && { log "[dry-run] status: $*"; return; }; printf '%s\n' "$*" >>"$REPORT_FILE"; }
init_report() { if [ "$DRY_RUN" = 1 ]; then log "[dry-run] initialize report $REPORT_FILE"; else : >"$REPORT_FILE"; rm -f "$NEEDS_REBOOT_FILE"; fi; }
record_status() { append_report "$1: $2"; }
mark_reboot_needed() { [ "$DRY_RUN" = 1 ] && log "[dry-run] mark reboot needed: $*" || printf '%s\n' "$*" >>"$NEEDS_REBOOT_FILE"; }

pacman_install() {
  [ "$#" -gt 0 ] || return
  command_exists omarchy || die "The Omarchy CLI is not installed"
  if [ ! -f /var/lib/pacman/sync/core.db ] || [ ! -f /var/lib/pacman/sync/extra.db ]; then
    die "Omarchy package databases are unavailable. Run 'omarchy update' once, then rerun this installer"
  fi
  if [ "$DRY_RUN" = 1 ]; then
    printf '[dry-run] omarchy pkg add'; printf ' %q' "$@"; printf '\n'
  else
    omarchy pkg add "$@"
  fi
}
kernel_headers_package() { local base; base="$(cat "/usr/lib/modules/$(uname -r)/pkgbase" 2>/dev/null || true)"; [ -n "$base" ] || die "Cannot determine kernel package for $(uname -r)"; printf '%s-headers\n' "$base"; }
update_initramfs() {
  if command_exists limine-mkinitcpio; then
    # Omarchy has no /etc/mkinitcpio.d presets. This root-only command invokes
    # its pacman hook directly and does not display the wrapper's Y/n prompt.
    run limine-mkinitcpio
  else
    die "limine-mkinitcpio is not installed; cannot rebuild Omarchy initramfs"
  fi
  mark_reboot_needed "initramfs updated"
}
clone_or_update_repo() { local url="$1" dest="$2"; ensure_dir "$(dirname "$dest")"; if [ -d "$dest/.git" ]; then run_in_dir "$dest" git pull --ff-only; elif [ -e "$dest" ]; then die "$dest exists but is not a git repository"; else run git clone "$url" "$dest"; fi; }
setup_user() { if [ -n "${SETUP_USER:-}" ]; then printf '%s\n' "$SETUP_USER"; elif [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then printf '%s\n' "$SUDO_USER"; elif command_exists logname && logname >/dev/null 2>&1; then logname; else awk -F: '$3 == 1000 {print $1; exit}' /etc/passwd; fi; }
model_name() { cat /sys/class/dmi/id/product_name 2>/dev/null || true; }
read_sysfs() { [ -r "$1" ] && cat "$1" 2>/dev/null || true; }
