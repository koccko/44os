#!/usr/bin/env python3
"""Parse-check QML files with Qt's own QML compiler (PyQt6).

Reports syntax and structural errors; unresolved imports (Plasma, KDE
modules that are not installed where this runs) are ignored.
Usage: check-qml.py FILE...
"""
import sys
from PyQt6.QtCore import QUrl
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlEngine, QQmlComponent
app = QGuiApplication(["x", "-platform", "offscreen"])
eng = QQmlEngine()
bad = 0
for f in sys.argv[1:]:
    c = QQmlComponent(eng, QUrl.fromLocalFile(f), QQmlComponent.CompilationMode.PreferSynchronous)
    errs = [e.toString() for e in c.errors() if "is not installed" not in e.description()
            and "module" not in e.description().lower()]
    if errs:
        bad += 1
        print("FAIL", f); [print("   ", e) for e in errs[:5]]
print("checked", len(sys.argv) - 1, "files,", bad, "with errors")
sys.exit(1 if bad else 0)
