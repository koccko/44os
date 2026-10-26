#!/bin/bash
exec > /out/probe.txt 2>&1
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq; apt-get install -y -qq apt-file binutils >/dev/null; apt-file update -q >/dev/null 2>&1
echo "=== owners"
for f in /usr/bin/krunner org/kde/taskmanager/qmldir /usr/bin/plasmashell look-and-feel/org.kde.breeze.desktop/contents/defaults sddm/themes/breeze/theme.conf plymouth/themes/spinner/spinner.plymouth kwin/aurorae aurorae/themes org/kde/plasma/plasmoid/qmldir /usr/bin/plasma-apply-wallpaperimage appmenu-gtk-module gmenudbusmenuproxy plasma-firstsetup; do
  echo "--- $f"; apt-file search "$f" | head -6; done
mkdir -p /tmp/d && cd /tmp/d
for p in plasma-workspace plasma-desktop sddm-theme-breeze plymouth-themes kwin-common kwin-wayland libtaskmanager6 qml6-module-org-kde-taskmanager plasma-workspace-data kde-style-breeze breeze; do apt-get download -qq "$p" 2>/dev/null || echo "no $p"; done
ls
mkdir -p x; for f in *.deb; do dpkg-deb -x "$f" x; done
echo "=== taskmanager qml"; find x -path '*org/kde/taskmanager*' | head
for q in $(find x -path '*org/kde/taskmanager*' -name '*.qmltypes'); do echo "--- $q"; grep -E 'name: "|Signal|Method|Property' "$q" | grep -oE 'name: "[A-Za-z_]+"' | sort -u | tr '\n' ' ' | head -c 9000; echo; done
echo "=== sddm breeze"; ls x/usr/share/sddm/themes/breeze; cat x/usr/share/sddm/themes/breeze/theme.conf; grep -ohE 'config\.[a-zA-Z]+' x/usr/share/sddm/themes/breeze/*.qml | sort -u
echo "=== breeze lnf"; find x -path '*look-and-feel/org.kde.breeze.desktop*' | head -30; cat x/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/defaults; cat x/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/metadata.json
echo "=== lnf layouts"; for f in $(find x -path '*look-and-feel*layouts*'); do echo "--- $f"; head -80 "$f"; done
echo "=== shell layout"; for f in $(find x -path '*shells/org.kde.plasma.desktop*' -name '*.js'); do echo "--- $f"; head -60 "$f"; done
echo "=== plasmashell strings"; strings x/usr/bin/plasmashell 2>/dev/null | grep -E '^(lengthMode|floating|hiding|opacity|alignment|fit|fill|custom|dodgewindows|autohide|windowsgobelow|translucent|adaptive)$' | sort -u
for l in $(find x -name 'libplasma*shell*.so*' -o -name 'libplasmashell*' | head); do echo "--- $l"; strings "$l" | grep -E 'lengthMode|dodgewindows|windowsgobelow' | head; done
echo "=== plymouth spinner"; cat x/usr/share/plymouth/themes/spinner/spinner.plymouth; ls x/usr/share/plymouth/themes/spinner | head -60; ls x/usr/share/plymouth/themes
echo "=== kwin effects"; find x -path '*kwin*effects*' | sed 's|.*/||' | sort -u | head -80
echo "=== aurorae"; find x -ipath '*aurorae*' | head -30
echo "=== plasmoids on disk"; find x/usr/share/plasma/plasmoids -maxdepth 1 | head -80
