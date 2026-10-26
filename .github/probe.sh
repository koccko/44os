#!/bin/bash
# Temporary probe of Debian trixie packages/files for the NOVA work.
exec > /out/probe.txt 2>&1
apt-get update -qq
echo "=== policy"
for p in python3-pyqt6 python3-pyqt6.qtquick python3-pyqt6.qtqml python3-pyqt6.qtdbus qml6-module-org-kde-kirigami qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-window qml6-module-qtqml-workerscript qt6-declarative-dev-tools fonts-inter plymouth plymouth-themes plymouth-label mesa-utils plasma-discover bluedevil power-profiles-daemon plasma-welcome kde-config-sddm plasma-session-x11 plasma-workspace-x11 kwin-x11 kwin-wayland kwin-addons kwin-common krunner milou plasma-systemmonitor kinfocenter qdbus-qt6 qt6-tools-dev-tools libqt6dbus6 python3-dbus accountsservice; do
  printf '%-36s %s\n' "$p" "$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate/{print $2}')"
done
mkdir -p /tmp/d && cd /tmp/d
apt-get download -qq kwin-common kwin-wayland sddm-theme-breeze plasma-workspace krunner plymouth plymouth-themes python3-pyqt6 plasma-desktop calamares 2>&1 | tail -2
for f in *.deb; do echo "=== $f"; dpkg -c "$f" | awk '{print $6}' | grep -E 'aurorae|sddm/themes/breeze/(theme.conf|Main.qml|metadata)|krunner.*desktop|org.kde.krunner|plymouth/themes/[^/]+/$|plymouth/themes/(bgrt|spinner)/|PyQt6/Qt[A-Z][a-zA-Z]+\.(abi3\.)?so|look-and-feel/org.kde.breeze.desktop/contents/(defaults|layouts)|kwin/effects/|kwin/scripts|systemtray|plasma/plasmoids/org.kde.plasma.(kickoff|icontasks|systemtray|appmenu|windowlist|digitalclock)' | head -80; done
mkdir -p x; for f in sddm-theme-breeze*.deb plasma-desktop*.deb plymouth-themes*.deb; do dpkg-deb -x "$f" x; done
echo "=== sddm breeze theme.conf"; cat x/usr/share/sddm/themes/breeze/theme.conf
echo "=== sddm Main.qml config refs"; grep -on 'config\.[a-zA-Z]*' x/usr/share/sddm/themes/breeze/*.qml | sort -u | head -40
echo "=== breeze lnf defaults"; cat x/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/defaults
echo "=== plasma-desktop layout.js"; find x -name 'layout.js' -path '*desktop*' | head; cat $(find x -name 'layout.js' -path '*org.kde.plasma.desktop/contents/layout.js') 2>/dev/null | head -60
echo "=== defaultPanel"; find x -path '*defaultPanel*' -name '*.js' -exec cat {} \; | head -80
echo "=== plymouth spinner theme"; cat x/usr/share/plymouth/themes/spinner/spinner.plymouth; ls x/usr/share/plymouth/themes/spinner | head -50
echo "=== plymouth bgrt"; cat x/usr/share/plymouth/themes/bgrt/bgrt.plymouth
