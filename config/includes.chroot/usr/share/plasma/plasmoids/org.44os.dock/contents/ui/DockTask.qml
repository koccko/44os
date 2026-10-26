/*
    One 44Dock item: a pinned launcher or a running application group.
    Uses the task model's roles through the Repeater's `model` object.

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

Item {
    id: task

    required property var dock      // the PlasmoidItem (geometry + helpers)
    required property var tasks     // TaskManager.TasksModel
    required property int index
    required property var model

    readonly property bool isLauncher: model.IsLauncher === true
    readonly property bool isStartup: model.IsStartup === true
    readonly property bool isRunning: !isLauncher && !isStartup
    readonly property int windowCount: model.IsGroupParent ? model.ChildCount : (isRunning ? 1 : 0)
    readonly property string title: model.AppName || model.display || ""

    // Magnification: computed from this item's rest position.
    readonly property real restCenter: (index + 0.5) * dock.slotWidth
    property real magnify: dock.scaleAt(restCenter)
    Behavior on magnify {
        NumberAnimation {
            duration: dock.hovering ? 70 : 220
            easing.type: Easing.OutCubic
        }
    }

    width: dock.slotWidth + dock.iconSize * (magnify - 1)

    function modelIndex() {
        return tasks.makeModelIndex(index);
    }

    function bounce() {
        if (Plasmoid.configuration.bounceOnLaunch && !bounceAnimation.running) {
            bounceAnimation.loops = 2;
            bounceAnimation.start();
        }
    }

    function cycleGroup() {
        // Activate the next window of a grouped application (macOS-like cycling).
        const parentIndex = modelIndex();
        let next = 0;
        for (let i = 0; i < model.ChildCount; ++i) {
            const child = tasks.makeModelIndex(index, i);
            if (tasks.data(child, TaskManager.AbstractTasksModel.IsActive)) {
                next = (i + 1) % model.ChildCount;
                break;
            }
        }
        tasks.requestActivate(tasks.makeModelIndex(index, next));
    }

    function activate() {
        if (isLauncher) {
            tasks.requestActivate(modelIndex());
            bounce();
        } else if (model.IsGroupParent && model.ChildCount > 1) {
            cycleGroup();
        } else if (model.IsActive && !model.IsMinimized) {
            tasks.requestToggleMinimized(modelIndex());
        } else {
            tasks.requestActivate(modelIndex());
        }
    }

    onIsStartupChanged: if (isStartup) bounce()

    PlasmaCore.ToolTipArea {
        id: toolTip
        anchors.fill: parent
        mainText: task.title
        subText: task.windowCount > 1 ? i18np("%1 window", "%1 windows", task.windowCount) : ""
        location: Plasmoid.location
        interactive: false

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    task.activate();
                } else if (mouse.button === Qt.MiddleButton) {
                    task.tasks.requestNewInstance(task.modelIndex());
                    task.bounce();
                } else if (mouse.button === Qt.RightButton) {
                    menuLoader.active = true;
                    if (menuLoader.item) {
                        menuLoader.item.openRelative();
                    }
                }
            }
        }
    }

    // Icon, scaled from its bottom-centre so it grows upwards.
    Item {
        id: iconHolder
        width: dock.iconSize * dock.maxScale
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        y: dock.iconBottom - height
        transform: Translate { id: lift; y: 0 }

        Kirigami.Icon {
            anchors.fill: parent
            source: task.model.decoration
            active: toolTip.containsMouse
            smooth: true
            scale: task.magnify / dock.maxScale
            transformOrigin: Item.Bottom
            opacity: task.isStartup ? 0.75 : 1
        }
    }

    // Running indicators: one dot per window, up to two.
    Row {
        visible: Plasmoid.configuration.showIndicators && task.isRunning
        anchors.horizontalCenter: parent.horizontalCenter
        y: dock.iconBottom + Math.round((parent.height - dock.iconBottom - height) / 2)
        spacing: 3

        Repeater {
            model: Math.min(2, Math.max(1, task.windowCount))
            Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: task.model.IsActive ? "#65A8FF" : "#A7B5CC"
                opacity: task.model.IsMinimized ? 0.55 : 1
            }
        }
    }

    // Launch / attention bounce.
    SequentialAnimation {
        id: bounceAnimation
        NumberAnimation { target: lift; property: "y"; to: -dock.iconSize * 0.28; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: lift; property: "y"; to: 0; duration: 260; easing.type: Easing.OutBounce }
    }
    SequentialAnimation {
        running: task.model.IsDemandingAttention === true
        loops: Animation.Infinite
        onRunningChanged: if (!running) lift.y = 0
        NumberAnimation { target: lift; property: "y"; to: -dock.iconSize * 0.22; duration: 260; easing.type: Easing.OutQuad }
        NumberAnimation { target: lift; property: "y"; to: 0; duration: 300; easing.type: Easing.OutBounce }
        PauseAnimation { duration: 900 }
    }

    // Context menu, created on first use so a menu problem can never break the dock.
    Loader {
        id: menuLoader
        active: false
        sourceComponent: DockMenu {
            visualParent: task
            dockTask: task
        }
    }
}
