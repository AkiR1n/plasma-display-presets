pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

MouseArea {
    id: root

    required property PlasmoidItem plasmoidItem

    implicitWidth: Kirigami.Units.iconSizes.medium
    implicitHeight: Kirigami.Units.iconSizes.medium

    onClicked: root.plasmoidItem.expanded = !root.plasmoidItem.expanded

    Kirigami.Icon {
        anchors.fill: parent
        source: Plasmoid.icon
    }
}
