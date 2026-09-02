# Linux on a 2016 MacBook Pro (MacBookPro13,3)

Hardware-fix and setup scripts for running several Linux distributions on a
2016 MacBook Pro with a T1 iBridge.

Choose the directory matching the installed system:

- [`ubuntu-26.04/`](ubuntu-26.04/) — Ubuntu 26.04
- [`omarchy-4/`](omarchy-4/) — Omarchy 4 (Arch Linux)

Each directory is self-contained apart from the Omarchy Wi-Fi installer, which
reuses the same machine-specific Broadcom NVRAM template as Ubuntu. Read that
directory's README and configuration before running anything.

The scripts target this particular MacBook model. They are not intended as a
generic installer for arbitrary Apple hardware.
