/*
    44Welcome — 44OS NOVA first-run application (UI).
    Backend: ../welcome.py (exposed as `backend`).
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: win

    // NOVA Glass design tokens
    readonly property color bg: "#080D18"
    readonly property color bg2: "#111A2B"
    readonly property color surface: "#18243A"
    readonly property color accent: "#65A8FF"
    readonly property color accent2: "#8B7CFF"
    readonly property color text1: "#F1F5FF"
    readonly property color text2: "#A7B5CC"
    readonly property color border: "#344765"
    readonly property color success: "#49D9AD"
    readonly property color warning: "#FFBE70"
    readonly property int radius: 14

    width: 1000
    height: 660
    minimumWidth: 860
    minimumHeight: 580
    visible: true
    title: "44Welcome"
    color: bg
    font.family: "Inter"
    font.pixelSize: 14

    readonly property var pages: [
        { key: "welcome", title: qsTr("Welcome"), glyph: "✦" },
        { key: "appearance", title: qsTr("Appearance"), glyph: "◐" },
        { key: "dock", title: qsTr("Dock"), glyph: "▭" },
        { key: "updates", title: qsTr("Updates"), glyph: "↻" },
        { key: "system", title: qsTr("System"), glyph: "▤" },
        { key: "about", title: qsTr("About 44OS"), glyph: "ⓘ" }
    ]
    property int current: Math.max(0, pages.findIndex(p => p.key === initialPage))

    onClosing: backend.markCompleted()

    // ---------------------------------------------------------------------
    // Reusable pieces

    component Card: Rectangle {
        radius: win.radius
        color: Qt.rgba(0.094, 0.141, 0.227, 0.72)     // surface, translucent
        border.color: Qt.rgba(0.204, 0.278, 0.396, 0.9)
        border.width: 1
    }

    component Heading: Label {
        color: win.text1
        font.pixelSize: 28
        font.weight: Font.Light
        wrapMode: Text.WordWrap
    }

    component Body: Label {
        color: win.text2
        font.pixelSize: 14
        wrapMode: Text.WordWrap
        lineHeight: 1.25
    }

    component NovaButton: Button {
        id: btn
        property bool primary: false
        implicitHeight: 38
        leftPadding: 18
        rightPadding: 18
        font.pixelSize: 14
        font.weight: Font.Medium
        contentItem: Label {
            text: btn.text
            font: btn.font
            color: btn.primary ? "#06101F" : win.text1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 19
            color: btn.primary ? (btn.down ? Qt.darker(win.accent, 1.15) : btn.hovered ? Qt.lighter(win.accent, 1.08) : win.accent)
                               : (btn.down ? "#22324F" : btn.hovered ? "#1E2C46" : win.surface)
            border.color: btn.primary ? "transparent" : win.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    component Choice: Rectangle {
        id: choice
        property string label
        property string detail
        property bool selected: false
        signal picked()
        implicitHeight: 64
        radius: 12
        color: selected ? Qt.rgba(0.396, 0.659, 1, 0.14) : (area.containsMouse ? "#1A2840" : "#141F33")
        border.color: selected ? win.accent : win.border
        border.width: selected ? 2 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2
            Label { text: choice.label; color: win.text1; font.weight: Font.Medium }
            Label { text: choice.detail; color: win.text2; font.pixelSize: 12; visible: text !== ""; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.picked() }
    }

    // ---------------------------------------------------------------------
    // Background glow
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0B1324" }
            GradientStop { position: 1.0; color: win.bg }
        }
    }
    Rectangle {
        width: parent.width * 0.9; height: width; radius: width / 2
        x: parent.width * 0.45; y: -height * 0.55
        color: win.accent; opacity: 0.07
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar ---------------------------------------------------------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 232
            color: Qt.rgba(0.067, 0.102, 0.169, 0.85)
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: win.border; opacity: 0.6 }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 6

                Image {
                    source: backend.brandingDir + "44os-nova-wordmark.png"
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 63
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    Layout.bottomMargin: 18
                    Layout.topMargin: 6
                }

                Repeater {
                    model: win.pages
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 10
                        color: win.current === index ? Qt.rgba(0.396, 0.659, 1, 0.16) : (navArea.containsMouse ? "#16223A" : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            visible: win.current === index
                            width: 3; height: 18; radius: 2
                            anchors.left: parent.left; anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: win.accent
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            spacing: 12
                            Label { text: modelData.glyph; color: win.current === index ? win.accent : win.text2; font.pixelSize: 15; Layout.preferredWidth: 18; horizontalAlignment: Text.AlignHCenter }
                            Label { text: modelData.title; color: win.current === index ? win.text1 : win.text2; font.weight: win.current === index ? Font.Medium : Font.Normal; Layout.fillWidth: true }
                        }
                        MouseArea { id: navArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.current = index }
                    }
                }

                Item { Layout.fillHeight: true }

                Label {
                    text: qsTr("Reopen 44Welcome any time from the application menu.")
                    color: win.text2; opacity: 0.8
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // Pages -------------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            StackLayout {
                id: stack
                currentIndex: win.current
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                Layout.preferredHeight: 0
                Layout.margins: 32

                // Welcome
                ColumnLayout {
                    spacing: 22
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(280, width * 0.4)
                        // Pre-rendered with rounded corners (branding/render.sh).
                        Image {
                            anchors.fill: parent
                            source: backend.brandingDir + "welcome-hero.png"
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 36
                            spacing: 8
                            Label { text: qsTr("Welcome to 44OS NOVA"); color: win.text1; font.pixelSize: 34; font.weight: Font.Light }
                            Label { text: qsTr("Your system. Your rules."); color: win.accent; font.pixelSize: 18; font.weight: Font.Medium }
                            Label {
                                text: qsTr("Version %1 · %2").arg(backend.version).arg(backend.base)
                                color: win.text2; font.pixelSize: 13; Layout.topMargin: 6
                            }
                        }
                    }
                    Body {
                        Layout.fillWidth: true
                        text: qsTr("44OS pairs a calm, macOS-inspired layout with the freedom of Debian and KDE Plasma. "
                                   + "Take a minute to make it yours: pick a look, tune the dock and check for updates.")
                    }
                    RowLayout {
                        spacing: 12
                        NovaButton { text: qsTr("Get started"); primary: true; onClicked: win.current = 1 }
                        NovaButton { text: qsTr("Install 44OS"); visible: backend.live; onClicked: backend.launchInstaller() }
                        NovaButton { text: qsTr("About 44OS"); onClicked: win.current = 5 }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 12
                        Repeater {
                            model: [
                                { t: qsTr("44Launcher"), d: qsTr("Press Super+Space to search apps, files and settings, or to calculate.") },
                                { t: qsTr("44Dock"), d: qsTr("Pinned apps and open windows. Right-click an icon to keep it in the dock.") },
                                { t: qsTr("Quick settings"), d: qsTr("Network, sound, Bluetooth, brightness and notifications live in the top-right corner.") }
                            ]
                            delegate: Card {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 96
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 4
                                    Label { text: modelData.t; color: win.text1; font.weight: Font.Medium }
                                    Body { text: modelData.d; font.pixelSize: 12; Layout.fillWidth: true }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Appearance
                ScrollView {
                    contentWidth: availableWidth
                    ColumnLayout {
                        width: parent.width
                        spacing: 16
                        Heading { text: qsTr("Appearance") }
                        Body { text: qsTr("Choose a style. NOVA Dark is the default."); Layout.fillWidth: true }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            property string theme: backend.colorScheme
                            id: themeRow
                            Choice { label: qsTr("NOVA Dark"); detail: qsTr("Deep navy glass, electric blue accents"); selected: themeRow.theme === "dark"; Layout.fillWidth: true; onPicked: { themeRow.theme = "dark"; backend.applyTheme("dark") } }
                            Choice { label: qsTr("NOVA Light"); detail: qsTr("Bright surfaces, the same blue accents"); selected: themeRow.theme === "light"; Layout.fillWidth: true; onPicked: { themeRow.theme = "light"; backend.applyTheme("light") } }
                        }
                        Label { text: qsTr("Wallpaper"); color: win.text1; font.weight: Font.Medium; Layout.topMargin: 8 }
                        Flow {
                            Layout.fillWidth: true
                            spacing: 12
                            Repeater {
                                model: backend.wallpapers
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 200; height: 136; radius: 12
                                    color: "#141F33"; border.color: wpArea.containsMouse ? win.accent : win.border; border.width: 1
                                    Image {
                                        anchors.fill: parent; anchors.margins: 6; anchors.bottomMargin: 30
                                        source: modelData.preview; fillMode: Image.PreserveAspectCrop; smooth: true
                                    }
                                    Label { anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: win.text1; font.pixelSize: 12 }
                                    MouseArea { id: wpArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.applyWallpaper(modelData.path) }
                                }
                            }
                        }
                        Label { text: qsTr("Visual effects"); color: win.text1; font.weight: Font.Medium; Layout.topMargin: 8 }
                        RowLayout {
                            id: fxRow
                            Layout.fillWidth: true
                            spacing: 12
                            property string mode: backend.effectsMode
                            Choice { label: qsTr("Automatic"); detail: qsTr("Reduce on software rendering"); selected: fxRow.mode === "auto"; Layout.fillWidth: true; onPicked: { fxRow.mode = "auto"; backend.setEffectsMode("auto") } }
                            Choice { label: qsTr("Full"); detail: qsTr("Blur, glass and animations"); selected: fxRow.mode === "full"; Layout.fillWidth: true; onPicked: { fxRow.mode = "full"; backend.setEffectsMode("full") } }
                            Choice { label: qsTr("Reduced"); detail: qsTr("Fastest on older hardware"); selected: fxRow.mode === "reduced"; Layout.fillWidth: true; onPicked: { fxRow.mode = "reduced"; backend.setEffectsMode("reduced") } }
                        }
                    }
                }

                // Dock
                ColumnLayout {
                    id: dockPage
                    spacing: 16
                    property string style: backend.dock.style || "44dock"
                    property string hiding: backend.dock.hiding || "dodgewindows"
                    property int magnification: backend.dock.magnification !== undefined ? backend.dock.magnification : 35
                    function apply() { backend.updateDock(style, hiding, magnification) }

                    Heading { text: qsTr("Dock") }
                    Body {
                        Layout.fillWidth: true
                        text: backend.dock.found === false
                              ? qsTr("No dock panel was found at the bottom of the screen.")
                              : qsTr("Changes apply immediately.")
                    }
                    Label { text: qsTr("Visibility"); color: win.text1; font.weight: Font.Medium }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Choice { label: qsTr("Always visible"); selected: dockPage.hiding === "none"; Layout.fillWidth: true; onPicked: { dockPage.hiding = "none"; dockPage.apply() } }
                        Choice { label: qsTr("Intelligent hide"); detail: qsTr("Hides when a window overlaps"); selected: dockPage.hiding === "dodgewindows"; Layout.fillWidth: true; onPicked: { dockPage.hiding = "dodgewindows"; dockPage.apply() } }
                        Choice { label: qsTr("Auto-hide"); detail: qsTr("Shows at the screen edge"); selected: dockPage.hiding === "autohide"; Layout.fillWidth: true; onPicked: { dockPage.hiding = "autohide"; dockPage.apply() } }
                    }
                    Label { text: qsTr("Style"); color: win.text1; font.weight: Font.Medium; Layout.topMargin: 6 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Choice { label: qsTr("44Dock"); detail: qsTr("Magnification, launch bounce, indicators"); selected: dockPage.style === "44dock"; Layout.fillWidth: true; onPicked: { dockPage.style = "44dock"; dockPage.apply() } }
                        Choice { label: qsTr("Classic"); detail: qsTr("Plasma's icon-only task manager"); selected: dockPage.style === "classic"; Layout.fillWidth: true; onPicked: { dockPage.style = "classic"; dockPage.apply() } }
                    }
                    Label { text: qsTr("Magnification"); color: win.text1; font.weight: Font.Medium; Layout.topMargin: 6; visible: dockPage.style === "44dock" }
                    RowLayout {
                        visible: dockPage.style === "44dock"
                        Layout.fillWidth: true
                        spacing: 14
                        Slider {
                            id: magSlider
                            from: 0; to: 60; stepSize: 5
                            value: dockPage.magnification
                            Layout.fillWidth: true
                            onMoved: { dockPage.magnification = value }
                            onPressedChanged: if (!pressed) dockPage.apply()
                            background: Rectangle {
                                x: magSlider.leftPadding; y: magSlider.topPadding + magSlider.availableHeight / 2 - height / 2
                                width: magSlider.availableWidth; height: 4; radius: 2; color: win.surface
                                Rectangle { width: magSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: win.accent }
                            }
                            handle: Rectangle {
                                x: magSlider.leftPadding + magSlider.visualPosition * (magSlider.availableWidth - width)
                                y: magSlider.topPadding + magSlider.availableHeight / 2 - height / 2
                                width: 18; height: 18; radius: 9; color: win.text1; border.color: win.accent; border.width: 2
                            }
                        }
                        Label { text: dockPage.magnification === 0 ? qsTr("Off") : dockPage.magnification + "%"; color: win.text2; Layout.preferredWidth: 44 }
                    }
                    Body {
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        text: qsTr("Magnification grows icons within the dock's height (Plasma clips widgets to their panel), so the effect is subtler than on macOS.")
                    }
                    Item { Layout.fillHeight: true }
                }

                // Updates
                ColumnLayout {
                    spacing: 16
                    Heading { text: qsTr("Updates") }
                    Body { Layout.fillWidth: true; text: qsTr("44OS receives Debian 13 security and stability updates. Discover installs them for you.") }
                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 20; spacing: 16
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                Label { text: qsTr("Software updates"); color: win.text1; font.pixelSize: 16; font.weight: Font.Medium }
                                Body { text: qsTr("Check for and install updates for the system and your applications."); Layout.fillWidth: true }
                            }
                            NovaButton { text: qsTr("Open Discover"); primary: true; onClicked: backend.openUpdates() }
                        }
                    }
                    Card {
                        visible: backend.live
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 20; spacing: 16
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                Label { text: qsTr("Install 44OS"); color: win.text1; font.pixelSize: 16; font.weight: Font.Medium }
                                Body { text: qsTr("You are running the live system. Install 44OS to keep your changes."); Layout.fillWidth: true }
                            }
                            NovaButton { text: qsTr("Install"); primary: true; onClicked: backend.launchInstaller() }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // System
                ScrollView {
                    contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 14
                    Heading { text: qsTr("System") }
                    Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: infoColumn.implicitHeight + 28
                        ColumnLayout {
                            id: infoColumn
                            anchors.fill: parent; anchors.margins: 14
                            spacing: 0
                            Repeater {
                                model: backend.systemInfo
                                delegate: RowLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 16
                                    Label { text: modelData.label; color: win.text2; Layout.preferredWidth: 150; Layout.topMargin: 7; Layout.bottomMargin: 7 }
                                    Label { text: modelData.value; color: win.text1; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                            }
                        }
                    }
                    RowLayout {
                        spacing: 12
                        NovaButton { text: qsTr("Info Center"); onClicked: backend.openInfoCenter() }
                        NovaButton { text: qsTr("System Settings"); onClicked: backend.openSystemSettings() }
                    }
                }
                }

                // About
                ColumnLayout {
                    spacing: 16
                    Image {
                        source: backend.brandingDir + "44os-nova-wordmark.png"
                        Layout.preferredWidth: 300; Layout.preferredHeight: 126
                        fillMode: Image.PreserveAspectFit
                    }
                    Body {
                        Layout.fillWidth: true
                        text: qsTr("44OS %1 — %2 Edition. Built on %3 with KDE Plasma 6, Calamares and free software from thousands of contributors.")
                              .arg(backend.version).arg(backend.codename).arg(backend.base)
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 12
                        NovaButton { text: qsTr("Project"); onClicked: Qt.openUrlExternally("https://github.com/koccko/44os") }
                        NovaButton { text: qsTr("Documentation"); onClicked: Qt.openUrlExternally("https://github.com/koccko/44os#readme") }
                        NovaButton { text: qsTr("Report an issue"); onClicked: Qt.openUrlExternally("https://github.com/koccko/44os/issues") }
                        NovaButton { text: qsTr("Debian"); onClicked: Qt.openUrlExternally("https://www.debian.org") }
                        NovaButton { text: qsTr("KDE"); onClicked: Qt.openUrlExternally("https://kde.org") }
                    }
                    Body {
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        text: qsTr("44OS artwork is original and licensed CC-BY-SA-4.0; 44OS code is GPL-2.0-or-later. Debian, KDE and Plasma are trademarks of their respective owners.")
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                color: Qt.rgba(0.067, 0.102, 0.169, 0.6)
                Rectangle { width: parent.width; height: 1; color: win.border; opacity: 0.6 }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 32
                    anchors.rightMargin: 24
                    spacing: 12
                    Label { text: backend.status; color: win.success; Layout.fillWidth: true; elide: Text.ElideRight }
                    NovaButton { text: qsTr("Back"); visible: win.current > 0; onClicked: win.current-- }
                    NovaButton {
                        text: win.current < win.pages.length - 1 ? qsTr("Next") : qsTr("Finish")
                        primary: true
                        onClicked: win.current < win.pages.length - 1 ? win.current++ : win.close()
                    }
                }
            }
        }
    }
}
