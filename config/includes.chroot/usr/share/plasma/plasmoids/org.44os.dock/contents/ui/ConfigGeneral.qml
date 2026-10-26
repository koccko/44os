import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_iconSize: iconSize.value
    property alias cfg_magnification: magnification.value
    property alias cfg_showIndicators: showIndicators.checked
    property alias cfg_bounceOnLaunch: bounceOnLaunch.checked

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: iconSize
            Kirigami.FormData.label: i18n("Icon size:")
            from: 24
            to: 96
        }
        QQC2.SpinBox {
            id: magnification
            Kirigami.FormData.label: i18n("Magnification (%):")
            from: 0
            to: 100
            stepSize: 5
        }
        QQC2.CheckBox {
            id: showIndicators
            text: i18n("Show running indicators")
        }
        QQC2.CheckBox {
            id: bounceOnLaunch
            text: i18n("Bounce while launching")
        }
    }
}
