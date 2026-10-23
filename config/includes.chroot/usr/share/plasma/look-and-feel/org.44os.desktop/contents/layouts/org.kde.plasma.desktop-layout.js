// 44OS default Plasma 6 layout.
// Plasma runs this once, when a user starts a session without an existing
// desktop configuration (new users, the live session and fresh installs).
// Existing user layouts are never touched.

var wallpaper = "file:///usr/share/wallpapers/44OS/";

// Desktop: 44OS wallpaper on every screen.
var desks = desktops();
for (var i = 0; i < desks.length; ++i) {
    desks[i].wallpaperPlugin = "org.kde.image";
    desks[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desks[i].writeConfig("Image", wallpaper);
    desks[i].writeConfig("FillMode", 2);
}

// Top bar: launcher and global menu on the left, centered clock,
// system tray on the right. Thin, edge-to-edge, translucent.
var top = new Panel;
top.location = "top";
top.height = 30;
top.floating = false;
top.hiding = "none";
try { top.opacity = "translucent"; } catch (e) {}

var kickoff = top.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "44os-start");
kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");

top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", 1);           // beside the time
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");

top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

// Dock: floating, centered, sized to its content.
var dock = new Panel;
dock.location = "bottom";
dock.height = 58;
dock.hiding = "none";
dock.floating = true;
try { dock.lengthMode = "fit"; } catch (e) {}
dock.alignment = "center";

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:firefox-esr.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:systemsettings.desktop"
].join(","));
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("iconSpacing", 2);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("indicateAudioStreams", true);
