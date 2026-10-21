# 44OS 0.1 Alpha — Live ISO build

Experimental Debian 13 (trixie) based KDE Plasma live image. This is **not yet an installable release**: the Calamares installer and the final 44OS branding have not been integrated or tested. Do not erase a physical disk with this alpha.

## Build with GitHub Actions (no Debian installation needed)

1. Create a new GitHub repository named `44OS` (private is fine).
2. Upload **all the contents** of this archive to the repository root, including `.github/workflows/build-iso.yml`. Preserve the directory structure. GitHub's browser upload may not reliably include hidden directories from some OS/file selectors; check that the workflow file appears in the repository.
3. Open **Actions** > **Build 44OS Live ISO** > **Run workflow**.
4. Wait for the build. If successful, download the `44OS-0.1-alpha-live-amd64` artifact and extract the ZIP to obtain the ISO and checksum.
5. Test in a VM first. After a successful boot test, write the ISO to USB with Rufus (DD mode if prompted).

## Notes

- GitHub Actions runners use Ubuntu, while live-build targets Debian trixie. This configuration is a **starting point**, not a verified successful build. Cross-distribution bootstrap issues may require adjustments.
- Hosted runners have storage, runtime, artifact size, and usage limitations. If the build fails, inspect its logs; do not assume an ISO exists.
- UEFI boot is intended; firmware compatibility must be tested.
- This alpha has no configured graphical installer and no final custom 44OS theme. A production installer must be added and validated before deployment.
- Package selection, firmware, networking, and boot configuration may need iteration based on actual logs.

## Local build on Debian 13

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools
sudo bash build-44os.sh
```

Output: `dist/44OS-0.1-alpha-live-amd64.iso` (if successful).
