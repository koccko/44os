/*
    Active application name for the 44OS menu bar (macOS-style app title).
    Sits left of the global menu; when an application does not export a
    global menu, its name is still shown here.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByVirtualDesktop: false
        filterByActivity: false
        filterByScreen: false
    }

    readonly property string appName: {
        const index = tasksModel.activeTask;
        if (!index || !index.valid) {
            return "";
        }
        return tasksModel.data(index, TaskManager.AbstractTasksModel.AppName)
            || tasksModel.data(index, Qt.DisplayRole) || "";
    }

    fullRepresentation: PlasmaComponents3.Label {
        text: root.appName !== "" ? root.appName : i18n("Desktop")
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        leftPadding: Kirigami.Units.smallSpacing
        rightPadding: Kirigami.Units.largeSpacing
        Layout.minimumWidth: Math.min(implicitWidth, Kirigami.Units.gridUnit * 14)
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.fillHeight: true
    }
}
