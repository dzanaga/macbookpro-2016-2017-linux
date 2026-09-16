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

On a fresh installation, repair Wi-Fi first and reboot so networking is
available for the driver downloads performed by the full repair:

```bash
sudo mbp2016 repair wifi
sudo reboot
sudo mbp2016 repair all
```

`repair all` checks the installed `linux-omarchy` version, applies the Limine
workaround for the affected bespoke kernel when necessary, installs the Cirrus
sound driver, installs the T1 Touch Bar/camera driver, configures USB-C power,
and installs the suspend workaround. Healthy components are skipped.

See [`mbp2016-cli/README.md`](mbp2016-cli/README.md) for every command, what it
downloads or changes, prerequisites, and recovery warnings.

## Previous installers

Earlier Bash-based installers are kept for reference and existing installations:

- [`legacy_scripts/ubuntu26.04/`](legacy_scripts/ubuntu26.04/) — Ubuntu 26.04
- [`legacy_scripts/omarchy4/`](legacy_scripts/omarchy4/) — Omarchy 4

New Omarchy installations should use the CLI. The legacy folders retain their
own configuration and detailed documentation.

The project targets T1-equipped MacBook Pro hardware and is not a generic
installer for arbitrary Apple computers.

## `linux-omarchy` 7.2.5-3 boot fix

The Omarchy bespoke kernel 7.2.5-3 enables Intel IOMMU by default. On the 2016
15-inch T1 model this can prevent NVMe discovery, break the Apple SPI keyboard
and trackpad, and hang AMD graphics initialization. The related investigation
and diagnostic evidence are tracked in
[Omarchy issue #12119](https://github.com/omacom/omarchy/issues/12119).

Apply the version-gated workaround with:

```bash
sudo mbp2016 repair bespoke-kernel
```

The command checks the installed `linux-omarchy` version. For the known
affected version, it writes a Limine drop-in adding `intel_iommu=off` only to
the `linux-omarchy` entry and runs `limine-update`. It does nothing when the
bespoke kernel is absent or the installed version is not the known affected
release. Reboot after it applies the patch.


## AMD Radeon Pro GPU & External Display / KVM Switch Fix (Omarchy / Hyprland)

On 15-inch models (`MacBookPro13,3` and `MacBookPro14,3`) with discrete AMD Radeon Pro graphics (Polaris 11 / Baffin: Radeon Pro 450/455/460/555/560), connecting an external display or toggling a USB-C / DisplayPort KVM switch can freeze the mouse/desktop or crash GTK4 apps (such as Nautilus).

### Why it happens
1. **DRM Atomic Modeset Bug:** Hyprland's backend (Aquamarine) attempts atomic DRM modesetting (`ATOMIC_ALLOW_MODESET ATOMIC_TEST_ONLY`) on the `amdgpu` driver. On this GPU over USB-C DisplayPort alternate mode, atomic modeset commits fail with `Invalid argument` (`EINVAL`).
2. **0x0 Geometry Fallback:** Aquamarine falls back to bringing up the external display with a modeless `0x0` geometry.
3. **Session Freeze & GTK4 Crashes:** GTK4 applications (such as Nautilus) crash with a segfault in `libwayland-client.so.0` (`wl_display_dispatch_queue_pending`) upon receiving a `wl_output` with zero dimensions/scale. Meanwhile, Omarchy's monitor recovery loop (`omarchy-hyprland-monitor-watch`) continuously triggers `hyprctl reload`, and the lock screen surface on the broken geometry causes cursor and input hangs.

### Fix on a new Omarchy installation
1. **Disable atomic modesetting in Aquamarine** so Hyprland uses legacy KMS modesetting:
   ```bash
   mkdir -p ~/.config/environment.d
   echo "AQ_NO_ATOMIC=1" >> ~/.config/environment.d/aquamarine.conf
   ```
   Also add to `~/.config/hypr/hyprland.lua`:
   ```lua
   hl.env("AQ_NO_ATOMIC", "1")
   ```

2. **Explicitly configure the external monitor mode** in `~/.config/hypr/monitors.lua` instead of relying solely on unconstrained `preferred` negotiation:
   ```lua
   -- Example for an external monitor on DP-1:
   hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "auto", scale = 1 })
   ```

3. **Restart the Wayland session**:
   ```bash
   uwsm stop
   ```


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

