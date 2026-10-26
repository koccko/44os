#!/usr/bin/python3
"""44Welcome: the 44OS NOVA first-run application.

Runs automatically once per user (first successful login) via
/etc/xdg/autostart/org.44os.welcome-autostart.desktop, which starts it with
--autostart. Completion is stored per user in ~/.config/44osrc
([Welcome] Completed=true). It can be reopened any time from the application
menu ("44Welcome").

Everything it changes goes through Plasma's own tools and D-Bus APIs
(plasma-apply-colorscheme, plasma-apply-wallpaperimage, PlasmaShell
evaluateScript, kwriteconfig6), so the desktop stays in a supported state.
"""
import argparse
import configparser
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from PyQt6.QtCore import QObject, QProcess, QUrl, pyqtProperty, pyqtSignal, pyqtSlot
from PyQt6.QtGui import QFont, QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

HERE = Path(__file__).resolve().parent
CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
STATE_FILE = CONFIG_HOME / "44osrc"
RELEASE_FILE = Path("/etc/44os-release")
WALLPAPER_ROOT = Path("/usr/share/wallpapers")


# --------------------------------------------------------------------------
# Small helpers

def read_state():
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.optionxform = str
    try:
        cfg.read(STATE_FILE)
    except configparser.Error:
        pass
    return cfg


def write_state(group, key, value):
    """Write one key to ~/.config/44osrc (prefers kwriteconfig6, falls back to Python)."""
    if shutil.which("kwriteconfig6"):
        subprocess.run(["kwriteconfig6", "--file", "44osrc", "--group", group, "--key", key, str(value)],
                       check=False)
        return
    cfg = read_state()
    if not cfg.has_section(group):
        cfg.add_section(group)
    cfg.set(group, key, str(value))
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, "w") as fh:
        cfg.write(fh, space_around_delimiters=False)


def welcome_completed():
    return read_state().get("Welcome", "Completed", fallback="false").lower() == "true"


def run(cmd, timeout=10):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, check=False)
        return out.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def read_release():
    info = {"NAME": "44OS", "VERSION": "0.6 Alpha", "CODENAME": "NOVA", "BASE": "Debian GNU/Linux 13 (trixie)"}
    try:
        for line in RELEASE_FILE.read_text().splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                info[k.strip()] = v.strip().strip('"')
    except OSError:
        pass
    return info


def is_live_session():
    try:
        return "boot=live" in Path("/proc/cmdline").read_text().split()
    except OSError:
        return False


def human_bytes(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or unit == "TB":
            return f"{n:.1f} {unit}" if unit not in ("B", "KB") else f"{int(n)} {unit}"
        n /= 1024
    return f"{n:.1f} TB"


# --------------------------------------------------------------------------
# System information (read-only, no root needed)

def system_info():
    rows = []
    kinfo = {}
    out = run(["kinfo"], timeout=8)
    for line in out.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            kinfo[k.strip()] = v.strip()

    rel = read_release()
    rows.append(("Operating system", f"{rel.get('NAME', '44OS')} {rel.get('VERSION', '')}".strip()))
    rows.append(("Foundation", rel.get("BASE", "Debian GNU/Linux 13 (trixie)")))

    cpu = ""
    try:
        for line in Path("/proc/cpuinfo").read_text().splitlines():
            if line.startswith("model name"):
                cpu = re.sub(r"\s+", " ", line.split(":", 1)[1]).strip()
                break
    except OSError:
        pass
    rows.append(("Processor", f"{cpu or 'Unknown'} ({os.cpu_count() or '?'} threads)"))

    mem = ""
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            if line.startswith("MemTotal:"):
                mem = human_bytes(int(line.split()[1]) * 1024)
                break
    except OSError:
        pass
    rows.append(("Memory", mem or "Unknown"))

    renderer = kinfo.get("Graphics Processor") or read_state().get("Effects", "LastRenderer", fallback="")
    drivers = sorted({p.resolve().name for p in Path("/sys/class/drm").glob("card*/device/driver") if p.exists()})
    gpu = renderer or "Unknown"
    if drivers:
        gpu += f"  ·  driver: {', '.join(drivers)}"
    rows.append(("Graphics", gpu))
    if renderer and re.search(r"llvmpipe|softpipe|Software Rasterizer", renderer):
        rows.append(("Rendering", "Software (effects are reduced automatically)"))
    else:
        rows.append(("Rendering", "Hardware accelerated" if renderer else "Unknown"))

    rows.append(("Kernel", kinfo.get("Kernel Version", os.uname().release)))
    rows.append(("Session", kinfo.get("Graphics Platform", os.environ.get("XDG_SESSION_TYPE", "unknown").title())))
    plasma = kinfo.get("KDE Plasma Version") or run(["plasmashell", "--version"]).replace("plasmashell", "").strip()
    rows.append(("KDE Plasma", plasma or "Unknown"))
    if kinfo.get("KDE Frameworks Version"):
        rows.append(("KDE Frameworks", kinfo["KDE Frameworks Version"]))
    from PyQt6.QtCore import qVersion
    rows.append(("Qt", kinfo.get("Qt Version", qVersion())))
    try:
        du = shutil.disk_usage("/")
        rows.append(("Storage (/)", f"{human_bytes(du.used)} used of {human_bytes(du.total)}"))
    except OSError:
        pass
    return [{"label": k, "value": v} for k, v in rows if v]


def wallpapers():
    items = []
    for pkg in sorted(WALLPAPER_ROOT.glob("44OS*")):
        images = pkg / "contents" / "images"
        best = images / "3840x2160.jpg"
        if not best.exists():
            cands = sorted(images.glob("*"))
            if not cands:
                continue
            best = cands[-1]
        name = pkg.name
        meta = pkg / "metadata.json"
        try:
            name = json.loads(meta.read_text())["KPlugin"]["Name"]
        except (OSError, KeyError, ValueError):
            pass
        preview = pkg / "contents" / "screenshot.jpg"
        items.append({"name": name, "path": str(best),
                      "preview": QUrl.fromLocalFile(str(preview if preview.exists() else best)).toString()})
    return items


# --------------------------------------------------------------------------
# Plasma shell scripting (panel / dock preferences)

def plasma_script(script):
    """Run a Plasma desktop script; returns (ok, output)."""
    try:
        import dbus
        bus = dbus.SessionBus()
        shell = bus.get_object("org.kde.plasmashell", "/PlasmaShell")
        out = shell.evaluateScript(script, dbus_interface="org.kde.PlasmaShell")
        return True, str(out or "")
    except Exception as exc:  # dbus missing, shell not running, script error
        return False, str(exc)


DOCK_QUERY = r"""
var r = {found: false};
var ps = panels();
for (var i = 0; i < ps.length; ++i) {
    var p = ps[i];
    if (p.location != "bottom") continue;
    r.found = true;
    r.hiding = p.hiding;
    var w = p.widgets("org.44os.dock");
    r.style = w.length > 0 ? "44dock" : "classic";
    if (w.length > 0) {
        w[0].currentConfigGroup = ["General"];
        r.magnification = parseInt(w[0].readConfig("magnification", 35));
    }
    break;
}
print(JSON.stringify(r));
"""

DOCK_UPDATE = r"""
var want = %s;
var ps = panels();
for (var i = 0; i < ps.length; ++i) {
    var p = ps[i];
    if (p.location != "bottom") continue;
    if (want.hiding) p.hiding = want.hiding;
    var docks = p.widgets("org.44os.dock");
    var classic = p.widgets("org.kde.plasma.icontasks");
    if (want.style == "classic" && docks.length > 0) {
        docks[0].currentConfigGroup = ["General"];
        var l = docks[0].readConfig("launchers", "");
        docks[0].remove();
        var t = p.addWidget("org.kde.plasma.icontasks");
        t.currentConfigGroup = ["General"];
        t.writeConfig("launchers", String(l));
    } else if (want.style == "44dock" && docks.length == 0 && classic.length > 0) {
        classic[0].currentConfigGroup = ["General"];
        var l2 = classic[0].readConfig("launchers", "");
        classic[0].remove();
        var d = p.addWidget("org.44os.dock");
        d.currentConfigGroup = ["General"];
        d.writeConfig("launchers", String(l2));
        docks = [d];
    }
    if (want.magnification !== undefined) {
        var ds = p.widgets("org.44os.dock");
        for (var j = 0; j < ds.length; ++j) {
            ds[j].currentConfigGroup = ["General"];
            ds[j].writeConfig("magnification", want.magnification);
            if (ds[j].reloadConfig) ds[j].reloadConfig();
        }
    }
}
"""


# --------------------------------------------------------------------------

class Backend(QObject):
    statusChanged = pyqtSignal()
    dockChanged = pyqtSignal()

    def __init__(self, autostart):
        super().__init__()
        self._release = read_release()
        self._live = is_live_session()
        self._status = ""
        self._dock = {}
        self._autostart = autostart
        self.refreshDock()

    # --- properties -------------------------------------------------------
    @pyqtProperty(str, constant=True)
    def version(self):
        return self._release.get("VERSION", "0.6 Alpha")

    @pyqtProperty(str, constant=True)
    def codename(self):
        return self._release.get("CODENAME", "NOVA")

    @pyqtProperty(str, constant=True)
    def base(self):
        return self._release.get("BASE", "Debian GNU/Linux 13 (trixie)")

    @pyqtProperty(bool, constant=True)
    def live(self):
        return self._live

    @pyqtProperty(str, constant=True)
    def brandingDir(self):
        return QUrl.fromLocalFile("/usr/share/44os/branding/").toString()

    @pyqtProperty("QVariantList", constant=True)
    def systemInfo(self):
        return system_info()

    @pyqtProperty("QVariantList", constant=True)
    def wallpapers(self):
        return wallpapers()

    @pyqtProperty(str, notify=statusChanged)
    def status(self):
        return self._status

    @pyqtProperty(str, constant=True)
    def colorScheme(self):
        out = run(["kreadconfig6", "--file", "kdeglobals", "--group", "General", "--key", "ColorScheme"])
        return "light" if out == "44OSNovaLight" else "dark"

    @pyqtProperty(str, constant=True)
    def effectsMode(self):
        return read_state().get("Effects", "Mode", fallback="auto")

    @pyqtProperty("QVariantMap", notify=dockChanged)
    def dock(self):
        return self._dock

    def _set_status(self, text):
        self._status = text
        self.statusChanged.emit()

    def _detached(self, program, args=()):
        if not shutil.which(program):
            self._set_status(f"{program} is not installed.")
            return False
        ok = QProcess.startDetached(program, list(args))[0]
        if not ok:
            self._set_status(f"Could not start {program}.")
        return ok

    # --- actions ----------------------------------------------------------
    @pyqtSlot(str)
    def applyTheme(self, variant):
        scheme, icons = ("44OSNovaLight", "breeze") if variant == "light" else ("44OSNova", "breeze-dark")
        run(["plasma-apply-colorscheme", scheme])
        run(["kwriteconfig6", "--file", "kdeglobals", "--group", "Icons", "--key", "Theme", icons])
        changeicons = Path("/usr/lib/x86_64-linux-gnu/libexec/plasma-changeicons")
        if changeicons.exists():
            run([str(changeicons), icons])
        self._set_status("Theme applied.")

    @pyqtSlot(str)
    def applyWallpaper(self, path):
        ok = subprocess.run(["plasma-apply-wallpaperimage", path], capture_output=True, check=False).returncode == 0 \
            if shutil.which("plasma-apply-wallpaperimage") else False
        run(["kwriteconfig6", "--file", "kscreenlockerrc", "--group", "Greeter", "--group", "Wallpaper",
             "--group", "org.kde.image", "--group", "General", "--key", "Image", f"file://{path}"])
        self._set_status("Wallpaper applied to the desktop and lock screen." if ok
                         else "Could not change the desktop wallpaper.")

    @pyqtSlot(str)
    def setEffectsMode(self, mode):
        if mode not in ("auto", "full", "reduced"):
            return
        write_state("Effects", "Mode", mode)
        run(["/usr/libexec/44os/session-setup"], timeout=20)
        self._set_status("Visual effects updated.")

    @pyqtSlot()
    def refreshDock(self):
        ok, out = plasma_script(DOCK_QUERY)
        data = {}
        if ok:
            for line in out.splitlines()[::-1]:
                try:
                    data = json.loads(line)
                    break
                except ValueError:
                    continue
        self._dock = data
        self.dockChanged.emit()

    @pyqtSlot(str, str, int)
    def updateDock(self, style, hiding, magnification):
        want = {"style": style, "hiding": hiding, "magnification": magnification}
        ok, out = plasma_script(DOCK_UPDATE % json.dumps(want))
        self._set_status("Dock updated." if ok else "Could not reach the Plasma shell.")
        self.refreshDock()

    @pyqtSlot()
    def openUpdates(self):
        if self._detached("plasma-discover", ["--mode", "update"]):
            self._set_status("Discover is opening the updates page.")

    @pyqtSlot()
    def openInfoCenter(self):
        self._detached("kinfocenter")

    @pyqtSlot()
    def openSystemSettings(self):
        self._detached("systemsettings")

    @pyqtSlot()
    def launchInstaller(self):
        self._detached("calamares-install-debian")

    @pyqtSlot()
    def markCompleted(self):
        write_state("Welcome", "Completed", "true")
        write_state("Welcome", "Version", self.version)


def main():
    parser = argparse.ArgumentParser(description="44OS NOVA welcome application")
    parser.add_argument("--autostart", action="store_true",
                        help="started at login: only show if this user has not completed it yet")
    parser.add_argument("--page", default="", help="open a specific page (welcome, appearance, dock, updates, system, about)")
    parser.add_argument("--snapshot", metavar="DIR", default="",
                        help="render every page to DIR/<page>.png and exit (documentation and tests)")
    args, qt_args = parser.parse_known_args()

    if args.autostart and welcome_completed():
        return 0
    if args.autostart and not args.snapshot:
        write_state("Welcome", "FirstShown", "true")

    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication([sys.argv[0]] + qt_args)
    app.setApplicationName("44welcome")
    app.setApplicationDisplayName("44Welcome")
    app.setDesktopFileName("org.44os.welcome")
    app.setWindowIcon(QIcon.fromTheme("44os-logo"))
    app.setFont(QFont("Inter", 10))

    backend = Backend(args.autostart)
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("initialPage", args.page)
    engine.load(QUrl.fromLocalFile(str(HERE / "qml" / "Main.qml")))
    if not engine.rootObjects():
        return 1
    if args.snapshot:
        ret = snapshot(app, engine.rootObjects()[0], Path(args.snapshot))
    else:
        # Mark as completed as soon as the user has seen it once, so it only
        # appears automatically on the first login.
        backend.markCompleted()
        ret = app.exec()
    del engine          # tear down QML before the backend it references
    return ret


def snapshot(app, window, outdir):
    from PyQt6 import sip
    from PyQt6.QtCore import QTimer
    from PyQt6.QtQuick import QQuickWindow
    window = sip.cast(window, QQuickWindow)
    outdir.mkdir(parents=True, exist_ok=True)
    pages = [p["key"] for p in window.property("pages").toVariant()] if hasattr(window.property("pages"), "toVariant") \
        else [p["key"] for p in window.property("pages")]
    state = {"i": 0}

    def step():
        i = state["i"]
        if i > 0:
            window.grabWindow().save(str(outdir / f"{pages[i - 1]}.png"))
        if i >= len(pages):
            app.quit()
            return
        window.setProperty("current", i)
        state["i"] = i + 1
        QTimer.singleShot(700, step)

    QTimer.singleShot(1200, step)
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
