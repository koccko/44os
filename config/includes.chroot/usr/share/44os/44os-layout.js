// 44OS 0.4 Plasma 6: minimal top bar + compact centered bottom dock.
// This script is only applied once to a new user's Plasma desktop.
var old = panels();
for (var i=0; i<old.length; ++i) old[i].remove();
var top = new Panel;
top.location = 'top';
top.height = 30;
top.addWidget('org.kde.plasma.kickoff');
top.addWidget('org.kde.plasma.appmenu');
top.addWidget('org.kde.plasma.panelspacer');
top.addWidget('org.kde.plasma.systemtray');
top.addWidget('org.kde.plasma.digitalclock');
var dock = new Panel;
dock.location = 'bottom';
dock.height = 58;
dock.hiding = 'none';
// Plasma 6 panel scripting accepts fit content and floating properties on supported versions.
// Unsupported properties are ignored; fallback remains a functional KDE panel.
try { dock.lengthMode = 'fit'; dock.alignment = 'center'; dock.floating = true; } catch(e) {}
var tasks = dock.addWidget('org.kde.plasma.icontasks');
var desks = desktops();
for (var j=0; j<desks.length; ++j) {
  desks[j].wallpaperPlugin = 'org.kde.image';
  desks[j].currentConfigGroup = ['Wallpaper','org.kde.image','General'];
  desks[j].writeConfig('Image','file:///usr/share/wallpapers/44OS/contents/images/1920x1080.svg');
  desks[j].writeConfig('FillMode',2);
}
