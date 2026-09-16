#!/usr/bin/env bash
set -Eeuo pipefail
CLI="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/mbp2016"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/sys/class/dmi/id" "$TMP/root/usr/lib/firmware/brcm"
printf 'MacBookPro13,3\n' >"$TMP/sys/class/dmi/id/product_name"

MBP2016_SYSFS_ROOT="$TMP/sys" MBP2016_ROOT="$TMP/root" "$CLI" version | grep -q '^mbp2016 '
MBP2016_SYSFS_ROOT="$TMP/sys" MBP2016_ROOT="$TMP/root" "$CLI" help | grep -q 'mbp2017'
json="$(MBP2016_SYSFS_ROOT="$TMP/sys" MBP2016_ROOT="$TMP/root" "$CLI" status --json || true)"
grep -q '"model":"MacBookPro13,3"' <<<"$json"
grep -q '"supported":true' <<<"$json"
grep -q '"touchbar":{"healthy":false}' <<<"$json"

affected_json="$(MBP2016_SYSFS_ROOT="$TMP/sys" MBP2016_ROOT="$TMP/root" \
  MBP2016_BESPOKE_KERNEL_VERSION=7.2.5-3 "$CLI" status --json || true)"
grep -q '"bespoke-kernel":{"healthy":false}' <<<"$affected_json"
mkdir -p "$TMP/root/etc/limine-entry-tool.d"
printf '%s\n' 'KERNEL_CMDLINE[linux-omarchy]+=" intel_iommu=off"' \
  >"$TMP/root/etc/limine-entry-tool.d/zz-mbp2016-intel-iommu.conf"
patched_json="$(MBP2016_SYSFS_ROOT="$TMP/sys" MBP2016_ROOT="$TMP/root" \
  MBP2016_BESPOKE_KERNEL_VERSION=7.2.5-3 "$CLI" status --json || true)"
grep -q '"bespoke-kernel":{"healthy":true}' <<<"$patched_json"

printf 'CLI tests passed\n'
