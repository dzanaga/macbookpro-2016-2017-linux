# Omarchy 4 on a 2016 MacBook Pro (MacBookPro13,3)

These scripts adapt the hardware fixes in this repository to Omarchy 4 / Arch
Linux. They use `pacman`, Arch kernel headers, the in-kernel Touch Bar drivers,
and Omarchy's non-interactive Limine/mkinitcpio integration. They do not run
Ubuntu checks or display the generic mkinitcpio wrapper's Limine prompt.

## Fresh install

Wi-Fi can be installed offline first:

```bash
sudo ./wifi.sh
sudo reboot
```

After connecting to Wi-Fi, run the complete setup:

```bash
sudo ./install.sh
```

Preview all mutations with:

```bash
DRY_RUN=1 ./install.sh
```

Review `config.env` first. Any `RUN_*` module can be disabled with `0`.

## Modules

- `10-misc.sh` installs Arch build/runtime prerequisites and optionally configures passwordless sudo.
- `20-wifi.sh` installs the BCM43602 NVRAM firmware and rebuilds initramfs with `limine-mkinitcpio`, without calling the interactive generic wrapper.
- `30-sound.sh` installs the MacBook Cirrus CS8409 driver through DKMS.
- `40-touchbar-camera.sh` replaces Omarchy's obsolete, unbuilt T1 package with a Linux 7.1-compatible `appleibridge` DKMS driver and a late, freeze-safe loader service. The in-tree `hid-appletb-*` modules are for T2 hardware and do not bind this Mac's `05ac:8600` T1 iBridge.
- `41-touchbar-settings.sh` applies `TOUCHBAR_FNMODE` and display timeouts live and persists them through a `touchbar.service` drop-in.
- `45-usbc-power.sh` keeps the Alpine Ridge USB-C controllers awake so external USB devices remain reliable.
- `50-suspend.sh` selects the requested sleep mode and reapplies hardware workarounds after resume.
- `90-report.sh` prints hardware, module, and service status.

The external sound driver is rebuilt by DKMS after kernel upgrades. If a new
kernel is installed alongside the current one, install its matching `*-headers`
package before booting it.

Packages are installed through `omarchy pkg add`; the installer never performs
a direct Pacman system upgrade. If the official package databases are absent,
run `omarchy update` once and then rerun this installer.

## Touch Bar mode

Set `TOUCHBAR_FNMODE` in `config.env` to `0`, `1`, `2`, or `3`, as documented
beside the setting. Apply it immediately and persistently with:

```bash
bash scripts/41-touchbar-settings.sh
```
