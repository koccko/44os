# 44OS 0.2 Alpha — installer integration test

Based on the user-verified bootable 44OS 0.1 Alpha (Debian 13, KDE Plasma). This iteration adds the Debian-packaged Calamares installer and `calamares-settings-debian` to the live image. **The ISO build and installer have NOT yet been tested.** No custom Petrol/Copper branding is included in this iteration.

## Build

Upload the **contents** of this folder to the root of the `koccko/44os` GitHub repository, preserving `.github/workflows/build-iso.yml`. Run the **Build 44OS Live ISO** workflow from Actions. Download the `44OS-0.2-alpha-live-amd64` artifact and extract its ZIP to obtain the ISO.

## VM installation acceptance test (VirtualBox)

1. Make a new disposable VM with 8 GB RAM, 4 vCPUs, 40 GB **new empty virtual disk**, EFI enabled, VMSVGA, and the ISO mounted. Disable unattended installation.
2. Boot live desktop; check networking and find Calamares in the application launcher. If missing, open Konsole and run `which calamares` and `ls /etc/calamares` to diagnose before trying anything else.
3. Open the installer and check that partitioning shows **only the disposable VM disk**. Do not test on a physical SSD.
4. Complete installation, power off, remove the ISO from the virtual optical drive, and boot from the virtual disk.
5. Confirm login, desktop, network, package updates, and boot persistence. Report errors/screenshots.

**Warning:** The Debian Calamares configuration may require additional live-specific integration and bootloader settings. Package installation alone does not prove the installer works. Keep 44OS 0.1 artifact as fallback. Do not deploy 0.2 to physical disks until the full VM test passes.
