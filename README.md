# Linux on 2016–2017 T1 MacBook Pro

Hardware support for `MacBookPro13,3` (2016) and `MacBookPro14,3` (2017),
including Wi-Fi, sound, Touch Bar, camera, USB-C power, and suspend fixes. Omarchy 4 and Ubuntu 26.06 supported. For Ubuntu see [`legacy_scripts/ubuntu26.04/`](legacy_scripts/ubuntu26.04/) .

**Note:**
Do not perform a full disk linux installation. MacOS dual boot is needed. Deleting the full disk will erase the T1 firmware on the EFI partition, which is needed to make the T1 chip work under linux.
More technical info on this detail can be found in the repos by [nohzafk](https://github.com/nohzafk/omarchy-macbookpro-t1) and [cschaba](https://github.com/cschaba/macbookpro14-3-linux).
If the T1 firmware has already been erased, [t1-revive](https://github.com/niconistal/t1-revive) can regenerate and restore it from Linux, although preservation and an off-disk `EFI/APPLE` backup remain strongly recommended.

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

### Drivers

- [Cirrus CS8409 sound driver](https://github.com/davidjo/snd_hda_macbookpro) — DKMS driver for speakers, microphones, and headphone switching.
- [Legacy T1 Touch Bar driver](https://github.com/parport0/mbp-t1-touchbar-driver) — Earlier Apple T1/iBridge Touch Bar driver and setup reference.

### Repositories

- [niconistal/t1-revive](https://github.com/niconistal/t1-revive) — Regenerates erased T1 firmware from Linux and restores Touch Bar, camera, and Touch ID support through T1Bridge.
- [nohzafk/omarchy-macbookpro-t1](https://github.com/nohzafk/omarchy-macbookpro-t1) — Omarchy guide and fixes for 2016–2017 T1 MacBook Pros.
- [cschaba/macbookpro14-3-linux](https://github.com/cschaba/macbookpro14-3-linux) — Linux hardware notes and setup for the 2017 15-inch MacBookPro14,3.
- [gavinmclelland/omarchy-macbookpro14-3](https://github.com/gavinmclelland/omarchy-macbookpro14-3) — Omarchy platform overlay for the MacBookPro14,3.

### Issues

- [omacom/omarchy#12119](https://github.com/omacom/omarchy/issues/12119) — `linux-omarchy` 7.2.5-3 needs `intel_iommu=off` to boot correctly on MacBookPro13,3.
- [omacom/omarchy#11619](https://github.com/omacom/omarchy/issues/11619) — CS8409 speakers and jack switching need the community sound driver on 2015–2017 models.
- [omacom/omarchy#11613](https://github.com/omacom/omarchy/issues/11613) — Missing board-specific BCM43602 NVRAM causes extremely weak Wi-Fi on MacBookPro13,3 and similar models.
- [omacom/omarchy#10826](https://github.com/omacom/omarchy/issues/10826) — The NVMe suspend fix targets the discrete GPU instead of NVMe on MacBookPro13,3.
- [omacom/omarchy#10825](https://github.com/omacom/omarchy/issues/10825) — The T1 Touch Bar stays dark because the legacy DKMS path does not build or bind all iBridge interfaces.
- [omacom/omarchy#10638](https://github.com/omacom/omarchy/issues/10638) — Stale `pcie_ports=compat` on T1 Macs breaks native PCIe hotplug and Thunderbolt dock tunneling.
- [omacom/omarchy#10466](https://github.com/omacom/omarchy/issues/10466) — A 2016 T1 MacBook Pro can remain throttled to 800 MHz after the screen saver runs.
- [omacom/omarchy#9831](https://github.com/omacom/omarchy/issues/9831) — Omarchy installs an obsolete SPI keyboard DKMS package even though `applespi` is in the kernel.
- [omacom/omarchy#9555](https://github.com/omacom/omarchy/issues/9555) — Screen recording can hang the AMD Baffin encoder and graphical session on dual-GPU models.
- [omacom/omarchy#9019](https://github.com/omacom/omarchy/issues/9019) — MacBookPro14,3 Wi-Fi also needs a regulatory domain; the existing BCM43602 quirk is insufficient.
- [omacom/omarchy#8323](https://github.com/omacom/omarchy/issues/8323) — Full-disk installation erases the EFI payload required by the MacBookPro13,3 T1/iBridge.
- [omacom/omarchy#8271](https://github.com/omacom/omarchy/issues/8271) — Installer needs to warn that replacing the Apple ESP disables T1/T2-attached hardware.
- [omacom/omarchy#7672](https://github.com/omacom/omarchy/issues/7672) — Missing BCM43602 calibration data leaves affected Macs with 2.4 GHz-only Wi-Fi.

### Pull requests

- [omacom/omarchy#11625](https://github.com/omacom/omarchy/pull/11625) — Installs the community CS8409 sound driver through DKMS on affected 2015–2017 MacBook Pros.
- [omacom/omarchy#11616](https://github.com/omacom/omarchy/pull/11616) — Adds board NVRAM to repair weak BCM43602 Wi-Fi reception.
- [omacom/omarchy#11570](https://github.com/omacom/omarchy/pull/11570) — Keeps Wi-Fi and USB-C working across S3 suspend on MacBookPro14,2.
- [omacom/omarchy#11516](https://github.com/omacom/omarchy/pull/11516) — Excludes the T1 Touch Bar DRM connector from external-display detection.
- [omacom/omarchy#11434](https://github.com/omacom/omarchy/pull/11434) — Reloads `brcmfmac` after resume when older MacBook Wi-Fi firmware becomes unresponsive.
- [omacom/omarchy#11064](https://github.com/omacom/omarchy/pull/11064) — Adds CS8409/MAX98706 speaker support specifically for the four T1 MacBook Pro models.
- [omacom/omarchy#10886](https://github.com/omacom/omarchy/pull/10886) — Migrates T1 Macs away from the PCIe compatibility mode that breaks hotplug.
- [omacom/omarchy#10141](https://github.com/omacom/omarchy/pull/10141) — Bundles model-specific Wi-Fi, Touch Bar, and experimental Radeon fixes for MacBookPro13,3.
- [omacom/omarchy#10125](https://github.com/omacom/omarchy/pull/10125) — Uses CPU encoding to avoid AMD Baffin GPU hangs during screen recording.
- [omacom/omarchy#9899](https://github.com/omacom/omarchy/pull/9899) — Prevents the roughly 130-second Thunderbolt/xHCI wake stall on 2016–2017 models.
- [omacom/omarchy#9880](https://github.com/omacom/omarchy/pull/9880) — Stops installing the obsolete out-of-tree Apple SPI keyboard driver.
- [omacom/omarchy#9516](https://github.com/omacom/omarchy/pull/9516) — Packages the CS8409 speaker driver for pre-T2 MacBook Pros and related iMacs.
- [omacom/omarchy#9062](https://github.com/omacom/omarchy/pull/9062) — Corrects the manual's T1 model list and excludes the non-T1 A1708.
- [omacom/omarchy#8285](https://github.com/omacom/omarchy/pull/8285) — Enables the external speaker amplifiers on pre-T2 CS8409 MacBooks.
- [omacom/omarchy#7950](https://github.com/omacom/omarchy/pull/7950) — Rebinds the T1 Touch Bar display sub-device so the bar lights up reliably.
- [omacom/omarchy#7671](https://github.com/omacom/omarchy/pull/7671) — Installs calibrated BCM43602 NVRAM for 2017 Touch Bar models to restore 5 GHz Wi-Fi.
- [omacom/omarchy#7487](https://github.com/omacom/omarchy/pull/7487) — Supplies missing BCM43602 NVRAM for Wi-Fi reliability on 2015–2017 MacBook Pros.
- [omacom/omarchy#7196](https://github.com/omacom/omarchy/pull/7196) — Avoids broken lid suspend and idles the Radeon GPU on 15-inch 2016–2017 models.
- [omacom/omarchy#7140](https://github.com/omacom/omarchy/pull/7140) — Adds a CS8409 speaker-driver installer verified on MacBookPro14,3.
- [omacom/omarchy#7064](https://github.com/omacom/omarchy/pull/7064) — Adds the EFI firmware handoff and `apple-ib-tb` wiring needed by T1 Touch Bars.
- [omacom/omarchy#7044](https://github.com/omacom/omarchy/pull/7044) — Keeps the Thunderbolt USB-C xHCI controller awake so devices reconnect after unplugging.
- [omacom/omarchy#12007](https://github.com/omacom/omarchy/pull/12007) — Removes `macbook12-spi-driver-dkms`, which no longer builds on Linux 7.x.
- [omacom/omarchy#11623](https://github.com/omacom/omarchy/pull/11623) — Closed combined attempt to fix BCM43602 Wi-Fi and CS8409 audio.
- [omacom/omarchy#11620](https://github.com/omacom/omarchy/pull/11620) — Closed earlier version of the CS8409 DKMS audio fix.
- [omacom/omarchy#10694](https://github.com/omacom/omarchy/pull/10694) — Closed proposal to install T1Bridge and fingerprint-management support safely.

### Other

- [Omacom discussion #2457](https://github.com/omacom/omarchy/discussions/2457) — Long-running installation and hardware-support discussion with T1 field reports.
- [Omacom Discord discussion](https://discord.com/channels/1390012484194275541/1545089063089082440) — Community thread for 2016/2017 MacBook Pro support.
- [Omarchy Mac support manual](https://github.com/omacom/omarchy/blob/quattro/manual/44-mac-support.md) — Omarchy's current Apple hardware guidance and support matrix.
- [MacBookPro13,2 Linux notes](https://github.com/xtocdra/macbookpro13-2) — General Linux notes for a 2016 13-inch T1 model.
- [Fedora Touch Bar setup notes](http://inku.bot.nu/posts/fedora-macbook2017/) — Distribution-independent background on enabling the 2017 Touch Bar.
- [Suspend/resume workaround](https://takachin.github.io/mbp2017-linux-note/en/suspend-resume.html) — Older reference for stabilizing suspend on a 2017 MacBook Pro.
