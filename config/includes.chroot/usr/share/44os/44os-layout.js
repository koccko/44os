// 44OS Plasma 6 initial layout, applied once per user.
var ps = panels();
for (var i = 0; i < ps.length; i++) { ps[i].remove(); }
var top = new Panel;
top.location = 'top';
top.height = 32;
top.addWidget('org.kde.plasma.kickoff');
top.addWidget('org.kde.plasma.appmenu');
top.addWidget('org.kde.plasma.panelspacer');
top.addWidget('org.kde.plasma.systemtray');
top.addWidget('org.kde.plasma.digitalclock');
var dock = new Panel;
dock.location = 'bottom';
dock.height = 62;
dock.hiding = 'none';
dock.addWidget('org.kde.plasma.icontasks');
var ds = desktops();
for (var j = 0; j < ds.length; j++) {
  ds[j].wallpaperPlugin = 'org.kde.image';
  ds[j].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
  ds[j].writeConfig('Image', 'file:///usr/share/wallpapers/44OS/contents/images/1920x1080.svg');
  ds[j].writeConfig('FillMode', 2);
}
