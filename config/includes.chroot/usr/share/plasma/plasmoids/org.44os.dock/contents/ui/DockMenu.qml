/*
    Context menu for a 44Dock item.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.Menu {
    id: menu

    required property var dockTask

    placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup

    PlasmaExtras.MenuItem {
        text: menu.dockTask.title
        section: true
    }

    PlasmaExtras.MenuItem {
        text: i18n("New Window")
        icon: "window-new"
        visible: menu.dockTask.isRunning && menu.dockTask.model.CanLaunchNewInstance === true
        onClicked: {
            menu.dockTask.tasks.requestNewInstance(menu.dockTask.modelIndex());
            menu.dockTask.bounce();
        }
    }

    PlasmaExtras.MenuItem {
        readonly property bool pinned: menu.dockTask.tasks.launcherPosition(menu.dockTask.model.LauncherUrlWithoutIcon) !== -1
        text: pinned ? i18n("Remove from Dock") : i18n("Keep in Dock")
        icon: pinned ? "window-unpin" : "window-pin"
        visible: menu.dockTask.model.LauncherUrlWithoutIcon && menu.dockTask.model.LauncherUrlWithoutIcon.toString() !== ""
        onClicked: menu.dockTask.dock.togglePinned(menu.dockTask.model.LauncherUrlWithoutIcon)
    }

    PlasmaExtras.MenuItem {
        separator: true
        visible: menu.dockTask.isRunning
    }

    PlasmaExtras.MenuItem {
        text: menu.dockTask.windowCount > 1 ? i18n("Close All Windows") : i18n("Close")
        icon: "window-close"
        visible: menu.dockTask.isRunning
        onClicked: menu.dockTask.tasks.requestClose(menu.dockTask.modelIndex())
    }
}
