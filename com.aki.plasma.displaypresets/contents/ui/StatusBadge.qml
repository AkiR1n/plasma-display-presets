pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: root

    property string text: ""
    property color fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.08))
    property color textColor: Kirigami.Theme.textColor
    property color borderColor: Qt.rgba(0, 0, 0, 0)
    property real horizontalPadding: Math.max(6, Kirigami.Units.smallSpacing * 0.85)
    property real verticalPadding: 2

    visible: root.text.length > 0
    radius: Math.round(implicitHeight / 2)
    color: root.fillColor
    border.width: root.borderColor.a > 0 ? 1 : 0
    border.color: root.borderColor
    implicitWidth: badgeLabel.implicitWidth + (root.horizontalPadding * 2)
    implicitHeight: badgeLabel.implicitHeight + (root.verticalPadding * 2)

    PlasmaComponents3.Label {
        id: badgeLabel
        anchors.centerIn: parent
        color: root.textColor
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: Font.Medium
        text: root.text
    }
}
