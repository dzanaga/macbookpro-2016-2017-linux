# mbp2016 CLI

`mbp2016` checks and repairs T1 hardware support on `MacBookPro13,3` (2016)
and `MacBookPro14,3` (2017). `mbp2017` is an alias for the same command.

## Install

Install the Arch package from the repository root:

```bash
cd mbp2016-cli/packaging/arch
makepkg -si
mbp2016 status
```

The package registers every installed file with Pacman, preserves local
configuration changes, and enables a boot-time Touch Bar health check. The boot
check only repairs an already-installed driver; it never downloads source or
upgrades packages.

The older Ubuntu 26.04 and Omarchy 4 installers remain available under
`legacy_scripts/`. The CLI currently uses the Omarchy 4 scripts as its repair
backend while their hardware logic is migrated into the packaged implementation.

## Use

```bash
mbp2016 status
mbp2016 status --json
sudo mbp2016 repair touchbar
sudo mbp2016 repair sound
sudo mbp2016 repair wifi
sudo mbp2016 repair all
mbp2016 logs touchbar
```

`repair` skips healthy components and may install packages or download driver
source. `reinstall` always runs the selected component installer again.
Run `mbp2016 help` for the full command list.
