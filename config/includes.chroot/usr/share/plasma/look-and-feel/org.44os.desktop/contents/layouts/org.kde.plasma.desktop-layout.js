// 44OS NOVA default Plasma 6 layout.
// Plasma runs this once, when a user starts a session without an existing
// desktop configuration (new users, the live session and fresh installs).
// Existing user layouts are never touched.

var wallpaper = "file:///usr/share/wallpapers/44OS-Nova/contents/images/3840x2160.jpg";

// Desktop: NOVA wallpaper on every screen.
var desks = desktops();
for (var i = 0; i < desks.length; ++i) {
    desks[i].wallpaperPlugin = "org.kde.image";
    desks[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desks[i].writeConfig("Image", wallpaper);
    desks[i].writeConfig("FillMode", 2);
}

// Menu bar ------------------------------------------------------------------
// Left: 44OS launcher, active application name, global application menu.
// Right: system tray (network, Bluetooth, volume, battery/brightness,
// notifications and the rest of the quick settings) and the clock.
var top = new Panel;
top.location = "top";
top.height = 32;
top.floating = false;
top.hiding = "none";
top.opacity = "translucent";

var kickoff = top.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "44os-start");
kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");

top.addWidget("org.44os.activeapp");

var appmenu = top.addWidget("org.kde.plasma.appmenu");
appmenu.currentConfigGroup = ["General"];
appmenu.writeConfig("compactView", false);

top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", 1);           // beside the time
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");

// 44Dock --------------------------------------------------------------------
// Floating, centred, sized to its content, moves out of the way of windows.
var dock = new Panel;
dock.location = "bottom";
dock.height = 72;
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "dodgewindows";
dock.opacity = "translucent";

var launchers = [
    "applications:org.44os.launcher.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:firefox-esr.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop"
];

var tasks = dock.addWidget("org.44os.dock");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", launchers.join(","));
tasks.writeConfig("iconSize", 44);
tasks.writeConfig("magnification", 35);
