# mbp2016 CLI

`mbp2016` checks and repairs T1 hardware support on `MacBookPro13,3` (2016)
and `MacBookPro14,3` (2017). `mbp2017` is an alias for the same command.

## Install

Install the Arch package from the repository root:

```bash
cd mbp2016-cli/packaging/arch
makepkg -si
```

The package registers every installed file with Pacman, preserves local
configuration changes, and enables a conservative boot-time Touch Bar health
check. That health check only repairs an already-installed driver; it never
downloads source or upgrades packages.

The older Ubuntu 26.04 and Omarchy 4 installers remain under
`legacy_scripts/`. The CLI currently uses the Omarchy 4 scripts as its repair
backend while their hardware logic is migrated into the packaged
implementation.

## Fresh installation: Wi-Fi first

A fresh installation usually has no working Wi-Fi, while the sound and Touch
Bar repairs need network access to download driver source. Run the Wi-Fi repair
first, then reboot:

```bash
sudo mbp2016 repair wifi
sudo reboot
```

Connect to Wi-Fi after reboot, then repair everything else:

```bash
sudo mbp2016 repair all
```

`repair all` skips components that already pass their health check. It checks
and repairs components in this order:

1. **Wi-Fi** — renders Broadcom BCM43602 NVRAM firmware with the Mac's live
   Wi-Fi address and configured regulatory country, installs it under
   `/usr/lib/firmware/brcm`, and rebuilds the initramfs.
2. **Bespoke kernel** — checks the installed `linux-omarchy` version. For the
   known affected 7.2.5-3 release, it adds `intel_iommu=off` to that Limine
   entry and rebuilds the boot entries. See
   [Omarchy issue #12119](https://github.com/omacom/omarchy/issues/12119).
3. **Sound** — downloads `davidjo/snd_hda_macbookpro`, installs matching kernel
   headers and build tools, and installs the Cirrus CS8409 driver through DKMS.
4. **Touch Bar and camera** — downloads the T1 `appleibridge` driver from
   `nohzafk/omarchy-macbookpro-t1`, builds it through DKMS, installs the
   Touch Bar loader service, and enables the T1 camera/ambient-light path.
5. **USB-C power** — installs a service and sleep hook that keep the matching
   Alpine Ridge USB-C controllers out of problematic low-power states.
6. **Suspend** — installs the selected `s2idle`/`deep` policy and a sleep hook
   that reapplies the USB-C power workaround after resume.

Reboot once `repair all` completes.

## Important macOS and T1 warning

Keep macOS or a recoverable Apple EFI/bridgeOS installation. Do not erase the
entire disk: these Macs depend on Apple firmware stored on the EFI system
partition for the T1 bridge, Touch Bar, keyboard/trackpad path, and related
hardware.

If `repair touchbar` reports USB device `05ac:1281`, the T1 is in recovery
mode. The Linux CLI cannot repair that firmware. Boot macOS/OpenCore Legacy
Patcher and restore bridgeOS/EFI first, then return to Linux and rerun the
repair.

## Commands

### Repair Wi-Fi

```bash
sudo mbp2016 repair wifi
```

Installs the machine-specific BCM43602 NVRAM firmware and rebuilds the
initramfs. Reboot afterward. Use this as the first repair on a fresh system so
the later commands can download their drivers.

### Repair all supported hardware

```bash
sudo mbp2016 repair all
```

Runs the version-gated bespoke-kernel repair plus Wi-Fi, sound, Touch Bar and
camera, USB-C power, and suspend repairs. Healthy components are skipped.

### Repair the Omarchy bespoke kernel entry

```bash
sudo mbp2016 repair bespoke-kernel
```

Checks the currently installed `linux-omarchy` package version. Version
7.2.5-3 is affected by default-on Intel IOMMU on `MacBookPro13,3` and may also
affect the closely related `MacBookPro14,3`. For that version only, the command
creates:

```text
/etc/limine-entry-tool.d/zz-mbp2016-intel-iommu.conf
```

The drop-in adds `intel_iommu=off` to the `linux-omarchy` entry, then the CLI
runs `limine-update`. The operation is idempotent and leaves stock-kernel boot
entries unchanged. Reboot and choose the `linux-omarchy` entry afterward.

The failure, diagnosis, kernel configuration difference, and workaround are
documented in
[omacom/omarchy#12119](https://github.com/omacom/omarchy/issues/12119).

### Repair sound

```bash
sudo mbp2016 repair sound
```

Downloads and installs the external Cirrus CS8409 MacBook Pro sound driver via
DKMS for the running kernel. Matching kernel headers and a network connection
are required. Reboot after installation.

### Repair Touch Bar and camera

```bash
sudo mbp2016 repair touchbar
sudo mbp2016 repair camera
```

Both commands currently run the same T1 bridge installer. It downloads and
builds the Linux 7.x-compatible `appleibridge` DKMS driver, installs the
Touch Bar loader and settings service, and enables the associated camera/ALS
modules.

This repair requires intact Apple T1/bridgeOS firmware. If the T1 is in
recovery mode, repair it from macOS/OpenCore Legacy Patcher first. Reboot after
the Linux driver installation.

### Repair USB-C power

```bash
sudo mbp2016 repair usbc
```

Installs a service and suspend hook that keep the MacBook's Alpine Ridge USB-C
controllers powered and optionally disable D3cold according to
`/etc/mbp2016.conf`.

### Repair suspend

```bash
sudo mbp2016 repair suspend
```

Installs systemd sleep configuration and hooks for the configured sleep mode,
then reapplies the USB-C power workaround after resume.

### Inspect status

```bash
mbp2016 status
mbp2016 status --json
```

Reports live health for Wi-Fi, the bespoke-kernel workaround, sound, Touch
Bar, camera, USB-C power, and suspend configuration.

### Force reinstallation

```bash
sudo mbp2016 reinstall sound
sudo mbp2016 reinstall touchbar
```

`repair` skips a component that already looks healthy. `reinstall` forces its
installer to run again. The bespoke-kernel command remains version-gated even
when invoked through `reinstall`.

### Touch Bar recovery and logs

```bash
sudo mbp2016 ensure touchbar
mbp2016 logs touchbar
```

`ensure touchbar` conservatively reloads an already-installed Touch Bar setup;
it does not download source. `logs touchbar` shows recent service and health
check messages.

Run `mbp2016 help` for the compact command reference.

## Configuration

Package defaults live in `/etc/mbp2016.conf`. Pacman preserves local changes.
The file controls the Wi-Fi regulatory country, Touch Bar mode/timeouts,
USB-C power handling, and suspend mode.
