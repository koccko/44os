#!/usr/bin/env bash
# Prepare a GitHub ubuntu-24.04 runner for VM tests: QEMU, OVMF, OCR, KVM access.
set -Eeuo pipefail
sudo rm -f /var/lib/man-db/auto-update
sudo apt-get update
sudo apt-get install -y --no-install-recommends qemu-system-x86 qemu-utils ovmf xorriso socat \
  tesseract-ocr tesseract-ocr-eng imagemagick e2fsprogs openssl
echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm.rules
sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=kvm
ls -l /dev/kvm
