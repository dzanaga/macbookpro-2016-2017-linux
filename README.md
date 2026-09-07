# Linux on 2016–2017 T1 MacBook Pro

Hardware support for `MacBookPro13,3` (2016) and `MacBookPro14,3` (2017),
including Wi-Fi, sound, Touch Bar, camera, USB-C power, and suspend fixes.

## Install

On Omarchy 4, clone this repository and install the Arch package:

```bash
cd mbp2016-cli/packaging/arch
makepkg -si
mbp2016 status
```

The installer also provides `mbp2017` as an alias and enables a conservative
Touch Bar health check at boot.

## Use

```bash
mbp2016 status
mbp2016 status --json
sudo mbp2016 repair touchbar
sudo mbp2016 reinstall touchbar
sudo mbp2016 repair sound
sudo mbp2016 repair wifi
sudo mbp2016 repair all
mbp2016 logs touchbar
```

See [`mbp2016-cli/README.md`](mbp2016-cli/README.md) for the full CLI guide.

## Previous installers

Earlier Bash-based installers are kept for reference and existing installations:

- [`legacy_scripts/ubuntu26.04/`](legacy_scripts/ubuntu26.04/) — Ubuntu 26.04
- [`legacy_scripts/omarchy4/`](legacy_scripts/omarchy4/) — Omarchy 4

New Omarchy installations should use the CLI. The legacy folders retain their
own configuration and detailed documentation.

The project targets T1-equipped MacBook Pro hardware and is not a generic
installer for arbitrary Apple computers.
