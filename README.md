# Linux on 2016–2017 T1 MacBook Pro

Hardware support for `MacBookPro13,3` (2016) and `MacBookPro14,3` (2017),
including Wi-Fi, sound, Touch Bar, camera, USB-C power, and suspend fixes. Omarchy 4 and Ubuntu 26.06 supported. For Ubuntu see [`legacy_scripts/ubuntu26.04/`](legacy_scripts/ubuntu26.04/) .

**Note:**
Do not perform a full disk linux installation. MacOS dual boot is needed. Deleting the full disk will erase the T1 firmware on the EFI partition, which is needed to make the T1 chip work under linux.
More technical info on this detail can be found in the repos by [nohzafk](https://github.com/nohzafk/omarchy-macbookpro-t1) and [cschaba](https://github.com/cschaba/macbookpro14-3-linux).

## Install

On Omarchy 4, clone this repository and run:

```bash
cd mbp2016-cli/packaging/arch
makepkg -si
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


## Links

[Omacom Discord discussion for the 2016/2017 MBP Pro](https://discord.com/channels/1390012484194275541/1545089063089082440)

Other repositories achieving the same (enabling Omarchy on T1 Macbook Pros), with extended documentation on the T1 workarounds:

- [nohzafk/omarchy-macbookpro-t1](https://github.com/nohzafk/omarchy-macbookpro-t1)
- [cschaba/macbookpro14-3-linux](https://github.com/cschaba/macbookpro14-3-linux)

Other links for more info:
- [Cirrus CS8409 sound driver](https://github.com/davidjo/snd_hda_macbookpro)
- [Legacy T1 Touch Bar driver](https://github.com/parport0/mbp-t1-touchbar-driver)
- [MacBookPro13,2 Linux notes](https://github.com/xtocdra/macbookpro13-2)
- [Fedora Touch Bar setup notes](http://inku.bot.nu/posts/fedora-macbook2017/)
- [Suspend/resume workaround](https://takachin.github.io/mbp2017-linux-note/en/suspend-resume.html)


