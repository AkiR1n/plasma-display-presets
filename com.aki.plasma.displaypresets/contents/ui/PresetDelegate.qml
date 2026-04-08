pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import "code/DisplayPreset.js" as PresetLogic

Rectangle {
    id: root

    readonly property string translationDomain: "plasma_applet_com.aki.plasma.displaypresets"
    required property var preset
    required property var autoRules
    required property bool busy
    required property bool isEditing
    required property bool isLastUsed
    required property string renameText
    required property bool autoBindingAvailable
    required property bool currentConnectionBound
    required property string currentConnectionSignature
    required property bool rulesExpanded
    required property int autoRuleCount
    required property var formatPresetSummary
    required property var formatAutoTrigger

    signal beginRename()
    signal renameInputEdited(string text)
    signal commitRename()
    signal cancelRename()
    signal restoreClicked()
    signal bindAutoClicked()
    signal overwriteClicked()
    signal deleteClicked()
    signal toggleRulesExpanded()
    signal autoRuleToggled(var rule, bool enabled)
    signal autoRuleDeleted(var rule)

    readonly property string presetSummary: root.formatPresetSummary(root.preset)
    readonly property real compactSpacing: Math.max(2, Kirigami.Units.smallSpacing * 0.55)
    readonly property real compactMargin: Math.max(3, Kirigami.Units.smallSpacing * 0.55)
    readonly property real compactButtonPadding: Math.max(3, Kirigami.Units.smallSpacing * 0.6)
    readonly property real compactButtonHeight: Math.max(Kirigami.Units.iconSizes.small + 6, Kirigami.Units.gridUnit * 1.45)

    radius: Kirigami.Units.cornerRadius
    color: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1,
        root.currentConnectionBound ? 0.05 : (root.isLastUsed ? 0.05 : 0.03)))
    border.width: root.currentConnectionBound ? 2 : 1
    border.color: root.currentConnectionBound
        ? Kirigami.Theme.highlightColor
        : Qt.tint(Kirigami.Theme.textColor, Qt.rgba(0, 0, 0, 0.75))

    implicitWidth: parent ? parent.width : Kirigami.Units.gridUnit * 20
    implicitHeight: content.implicitHeight + (root.compactMargin * 2)

    QQC2.Menu {
        id: moreMenu
        x: moreButton.x
        y: moreButton.y + moreButton.height

        QQC2.MenuItem {
            enabled: !root.busy
            text: i18nd(root.translationDomain, "Overwrite Current Layout")
            onTriggered: root.overwriteClicked()
        }

        QQC2.MenuItem {
            enabled: !root.busy
            text: i18nd(root.translationDomain, "Rename")
            onTriggered: root.beginRename()
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: !root.busy
            text: i18nd(root.translationDomain, "Delete")
            onTriggered: root.deleteClicked()
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.compactMargin
        spacing: root.compactSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: root.compactSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                font.weight: Font.DemiBold
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                elide: Text.ElideRight
                text: root.preset.name
                visible: !root.isEditing
            }

            QQC2.TextField {
                id: renameField
                Layout.fillWidth: true
                enabled: !root.busy
                selectByMouse: true
                text: root.renameText
                visible: root.isEditing
                onTextChanged: root.renameInputEdited(text)
                onAccepted: root.commitRename()
            }

            PlasmaComponents3.ToolButton {
                id: moreButton
                visible: !root.isEditing
                enabled: !root.busy
                icon.name: "application-menu"
                text: i18nd(root.translationDomain, "More actions")
                display: PlasmaComponents3.AbstractButton.IconOnly
                implicitWidth: Kirigami.Units.iconSizes.smallMedium + root.compactButtonPadding
                implicitHeight: Kirigami.Units.iconSizes.smallMedium + root.compactButtonPadding
                onClicked: moreMenu.open()
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: text
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: !root.isEditing
            spacing: root.compactSpacing
            width: parent.width

            StatusBadge {
                text: root.currentConnectionBound ? i18nd(root.translationDomain, "Current match") : ""
                fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(0, 0, 0, 0.18))
                borderColor: Qt.tint(Kirigami.Theme.highlightColor, Qt.rgba(1, 1, 1, 0.15))
                textColor: Kirigami.Theme.textColor
            }

            StatusBadge {
                text: root.isLastUsed ? i18nd(root.translationDomain, "Last used") : ""
                fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.08))
                textColor: Kirigami.Theme.textColor
            }

            StatusBadge {
                text: root.autoRuleCount > 0 ? i18nd(root.translationDomain, "Auto %1", root.autoRuleCount) : ""
                fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.08))
                textColor: Kirigami.Theme.linkColor
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            text: root.presetSummary
            visible: root.rulesExpanded && root.presetSummary.length > 0
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: root.compactSpacing

            PlasmaComponents3.Button {
                enabled: !root.busy && !root.isEditing
                icon.name: "view-refresh"
                text: i18nd(root.translationDomain, "Restore")
                visible: !root.isEditing
                implicitHeight: root.compactButtonHeight
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                leftPadding: root.compactButtonPadding * 1.2
                rightPadding: root.compactButtonPadding * 1.2
                topPadding: 1
                bottomPadding: 1
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                onClicked: root.restoreClicked()
            }

            PlasmaComponents3.Button {
                enabled: !root.busy
                icon.name: "list-add"
                text: i18nd(root.translationDomain, "Bind")
                visible: !root.isEditing && root.autoBindingAvailable && !root.currentConnectionBound
                implicitHeight: root.compactButtonHeight
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                leftPadding: root.compactButtonPadding
                rightPadding: root.compactButtonPadding
                topPadding: 1
                bottomPadding: 1
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                onClicked: root.bindAutoClicked()
            }

            PlasmaComponents3.Button {
                enabled: !root.busy && root.renameText.trim().length > 0
                icon.name: "dialog-ok"
                text: i18nd(root.translationDomain, "Save")
                visible: root.isEditing
                leftPadding: root.compactButtonPadding
                rightPadding: root.compactButtonPadding
                topPadding: 2
                bottomPadding: 2
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                onClicked: root.commitRename()
            }

            PlasmaComponents3.Button {
                enabled: !root.busy
                icon.name: "dialog-cancel"
                text: i18nd(root.translationDomain, "Cancel")
                visible: root.isEditing
                leftPadding: root.compactButtonPadding
                rightPadding: root.compactButtonPadding
                topPadding: 2
                bottomPadding: 2
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                onClicked: root.cancelRename()
            }

            Item {
                Layout.fillWidth: true
            }

            PlasmaComponents3.Button {
                enabled: !root.busy
                icon.name: root.rulesExpanded ? "go-up" : "go-down"
                text: i18nd(root.translationDomain, "Rules (%1)", root.autoRuleCount)
                visible: !root.isEditing && root.autoRuleCount > 0
                implicitHeight: root.compactButtonHeight
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                leftPadding: root.compactButtonPadding
                rightPadding: root.compactButtonPadding
                topPadding: 1
                bottomPadding: 1
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                onClicked: root.toggleRulesExpanded()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: !root.isEditing && root.autoRuleCount > 0 && root.rulesExpanded

            Repeater {
                model: root.autoRules

                delegate: Rectangle {
                    id: ruleCard

                    required property var modelData
                    readonly property var rule: modelData
                    readonly property bool isCurrentRule: rule.trigger.signature === root.currentConnectionSignature

                    Layout.fillWidth: true
                    radius: Kirigami.Units.cornerRadius
                    color: isCurrentRule
                        ? Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.10))
                        : Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.04))
                    border.width: isCurrentRule ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                    implicitHeight: ruleRow.implicitHeight + 4

                    RowLayout {
                        id: ruleRow
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: root.compactSpacing

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            text: root.formatAutoTrigger(rule.trigger)
                        }

                        StatusBadge {
                            text: ruleCard.isCurrentRule ? i18nd(root.translationDomain, "Current") : ""
                            fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(0, 0, 0, 0.18))
                            borderColor: Qt.tint(Kirigami.Theme.highlightColor, Qt.rgba(1, 1, 1, 0.15))
                            textColor: Kirigami.Theme.textColor
                        }

                        QQC2.Switch {
                            checked: !!ruleCard.rule.enabled
                            enabled: !root.busy
                            text: ""
                            implicitWidth: Kirigami.Units.gridUnit * 2.2
                            onClicked: root.autoRuleToggled(ruleCard.rule, checked)
                        }

                        PlasmaComponents3.ToolButton {
                            enabled: !root.busy
                            icon.name: "edit-delete"
                            text: i18nd(root.translationDomain, "Delete")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium + 2
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium + 2
                            onClicked: root.autoRuleDeleted(ruleCard.rule)
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: text
                        }
                    }
                }
            }
        }
    }

    onIsEditingChanged: {
        if (root.isEditing) {
            renameField.forceActiveFocus();
            renameField.selectAll();
        } else {
            moreMenu.close();
        }
    }
}
