/*
    44Dock: a macOS-inspired task manager for a floating Plasma panel.

    - Pinned launchers and running applications (grouped per application)
      from KDE's own TaskManager model, so launching, activation, pinning and
      window state behave exactly like Plasma's task managers.
    - Hover magnification: icons near the pointer grow and push their
      neighbours apart. Plasma clips applets to the panel, so the maximum
      scale is limited by the panel thickness (see maxScale).
    - Running indicators, launch bounce, attention bounce, tooltips,
      a context menu (new window, pin/unpin, close) and drop-to-pin.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Geometry ---------------------------------------------------------------
    readonly property real thickness: fullRepresentationItem ? fullRepresentationItem.height : 64
    readonly property real indicatorSpace: 8
    readonly property real iconSize: Math.max(16, Math.min(Plasmoid.configuration.iconSize,
                                                           thickness - 2 * indicatorSpace))
    readonly property real gap: Math.round(iconSize * 0.22)
    readonly property real slotWidth: iconSize + gap
    // Icons rest vertically centred and grow upwards from their bottom edge.
    readonly property real iconBottom: Math.round((thickness + iconSize) / 2)
    readonly property real maxScale: Math.max(1, Math.min(1 + Plasmoid.configuration.magnification / 100,
                                                          (iconBottom - 2) / iconSize))
    readonly property bool magnifies: maxScale > 1.02
    readonly property real influence: slotWidth * 2.5
    // Extra width reserved so the dock does not resize while magnifying.
    readonly property real reserve: magnifies ? Math.ceil(iconSize * (maxScale - 1) * 2.4) : 0

    // Pointer state, in "rest" row coordinates (row as if nothing were magnified).
    property bool hovering: false
    property real pointerX: -1

    function scaleAt(restCenter) {
        if (!magnifies || !hovering) {
            return 1;
        }
        const d = Math.abs(restCenter - pointerX);
        if (d >= influence) {
            return 1;
        }
        const t = Math.cos(d / influence * Math.PI / 2);
        return 1 + (maxScale - 1) * t * t;
    }

    // Task model ---------------------------------------------------------------
    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasksModel

        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        sortMode: TaskManager.TasksModel.SortManual
        separateLaunchers: false
        launchInPlace: true
        hideActivatedLaunchers: true
        filterByVirtualDesktop: false
        filterByScreen: false
        filterByActivity: true
        filterHidden: true
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop
        screenGeometry: Plasmoid.containment.screenGeometry

        launcherList: Plasmoid.configuration.launchers
        onLauncherListChanged: {
            if (JSON.stringify(launcherList) !== JSON.stringify(Plasmoid.configuration.launchers)) {
                Plasmoid.configuration.launchers = launcherList;
            }
        }
    }

    function togglePinned(url) {
        if (!url || url.toString() === "") {
            return;
        }
        if (tasksModel.launcherPosition(url) !== -1) {
            tasksModel.requestRemoveLauncher(url);
        } else {
            tasksModel.requestAddLauncher(url);
        }
    }

    // Representation -----------------------------------------------------------
    fullRepresentation: Item {
        id: dockItem

        readonly property real restRowWidth: tasksModel.count * root.slotWidth

        Layout.minimumWidth: Math.max(root.slotWidth, restRowWidth + root.reserve)
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.fillHeight: true

        HoverHandler {
            id: hover
            onHoveredChanged: root.hovering = hovered
            onPointChanged: {
                // Map the pointer into rest coordinates of the centred row.
                root.pointerX = point.position.x - (dockItem.width - dockItem.restRowWidth) / 2;
            }
        }

        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onDropped: drop => {
                for (const url of drop.urls) {
                    if (url.toString().endsWith(".desktop")) {
                        tasksModel.requestAddLauncher(url);
                    }
                }
                drop.accept(Qt.CopyAction);
            }
        }

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height

            Repeater {
                model: tasksModel
                delegate: DockTask {
                    dock: root
                    tasks: tasksModel
                    height: row.height
                }
            }
        }
    }
}
