#!/bin/bash
exec > /out/probe.txt 2>&1
apt-get update -qq
mkdir -p /tmp/d && cd /tmp/d
for p in plasma-desktop plasma-workspace libtaskmanager6 kwin-common libplasma6 plasma-workspace-data qml6-module-org-kde-kirigami; do apt-get download -qq "$p" 2>/dev/null || echo "no $p"; done
mkdir -p x; for f in *.deb; do dpkg-deb -x "$f" x; done
echo "=== taskmanager applet files"; find x -path '*plasmoids/org.kde.plasma.taskmanager*' -o -path '*plasmoids/org.kde.plasma.icontasks*' | head -40
echo "=== qmltypes enums"; python3 - <<'PY'
import re,glob
for f in glob.glob('x/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/taskmanager/*.qmltypes'):
    s=open(f).read()
    for m in re.finditer(r'Enum \{\s*name: "(\w+)"[^}]*?values: \[([^\]]*)\]', s, re.S):
        print(m.group(1), ':', re.sub(r'\s+',' ',m.group(2))[:1500])
    for m in re.finditer(r'Component \{[^{]*?name: "([\w:]+)"[^{]*?exports: \[([^\]]*)\]', s, re.S):
        print('COMPONENT', m.group(1), m.group(2).strip()[:200])
PY
echo "=== appmenu"; find x/usr/share/plasma/plasmoids/org.kde.plasma.appmenu | head; for f in $(find x/usr/share/plasma/plasmoids/org.kde.plasma.appmenu -name '*.qml' -o -name 'metadata.json' | head -3); do echo "--- $f"; head -120 "$f"; done
echo "=== icon applet"; for f in $(find x/usr/share/plasma/plasmoids/org.kde.plasma.icon -type f | head -5); do echo "--- $f"; head -80 "$f"; done
echo "=== plasmoid qml module"; find x -path '*org/kde/plasma/plasmoid*' | head; find x -path '*org/kde/plasma/core/qmldir' -exec cat {} \;
echo "=== plasmoid qmltypes"; for q in $(find x -path '*org/kde/plasma/plasmoid*' -name '*.qmltypes'); do grep -oE 'name: "[A-Za-z_]+"' "$q" | sort -u | tr '\n' ' ' | head -c 5000; echo; done
echo "=== aurorae package structure strings"; strings x/usr/lib/x86_64-linux-gnu/qt6/plugins/kf6/packagestructure/kwin_aurorae.so | grep -iE 'aurorae|svg|rc$' | head -20
strings x/usr/lib/x86_64-linux-gnu/qt6/plugins/org.kde.kdecoration3/org.kde.kwin.aurorae.so | grep -E '^[A-Z][A-Za-z]+$' | sort -u | head -120
echo "=== aurorae qml"; find x -path '*aurorae*' | head -40
