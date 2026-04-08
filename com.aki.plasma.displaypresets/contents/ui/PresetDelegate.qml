pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import "code/DisplayPreset.js" as PresetLogic

Rectangle {
    id: root

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

    readonly property real compactSpacing: Math.max(4, Kirigami.Units.smallSpacing * 0.85)
    readonly property real compactMargin: Kirigami.Units.smallSpacing

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
            text: i18n("Overwrite Current Layout")
            onTriggered: root.overwriteClicked()
        }

        QQC2.MenuItem {
            enabled: !root.busy
            text: i18n("Rename")
            onTriggered: root.beginRename()
        }

        QQC2.MenuSeparator {
        }

        QQC2.MenuItem {
            enabled: !root.busy
            text: i18n("Delete")
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
                text: i18n("More actions")
                display: PlasmaComponents3.AbstractButton.IconOnly
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
                text: root.currentConnectionBound ? i18n("Current match") : ""
                fillColor: Qt.tint(Kirigami.Theme.highlightColor, Qt.rgba(1, 1, 1, 0.92))
                textColor: Kirigami.Theme.highlightColor
            }

            StatusBadge {
                text: root.isLastUsed ? i18n("Last used") : ""
                fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.08))
                textColor: Kirigami.Theme.textColor
            }

            StatusBadge {
                text: root.autoRuleCount > 0 ? i18n("Auto %1", root.autoRuleCount) : ""
                fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.08))
                textColor: Kirigami.Theme.linkColor
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            text: PresetLogic.describePreset(root.preset)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: root.compactSpacing

            PlasmaComponents3.Button {
                enabled: !root.busy && !root.isEditing
                icon.name: "view-refresh"
                text: i18n("Restore")
                visible: !root.isEditing
                onClicked: root.restoreClicked()
            }

            PlasmaComponents3.Button {
                enabled: !root.busy
                icon.name: "list-add"
                text: i18n("Bind")
                visible: !root.isEditing && root.autoBindingAvailable && !root.currentConnectionBound
                onClicked: root.bindAutoClicked()
            }

            PlasmaComponents3.Button {
                enabled: !root.busy && root.renameText.trim().length > 0
                icon.name: "dialog-ok"
                text: i18n("Save")
                visible: root.isEditing
                onClicked: root.commitRename()
            }

            PlasmaComponents3.Button {
                enabled: !root.busy
                icon.name: "dialog-cancel"
                text: i18n("Cancel")
                visible: root.isEditing
                onClicked: root.cancelRename()
            }

            Item {
                Layout.fillWidth: true
            }

            PlasmaComponents3.Button {
                enabled: !root.busy
                icon.name: root.rulesExpanded ? "go-up" : "go-down"
                text: i18n("Rules (%1)", root.autoRuleCount)
                visible: !root.isEditing && root.autoRuleCount > 0
                onClicked: root.toggleRulesExpanded()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.max(2, root.compactSpacing * 0.75)
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
                    implicitHeight: ruleRow.implicitHeight + (Math.max(2, root.compactSpacing * 0.75) * 2)

                    RowLayout {
                        id: ruleRow
                        anchors.fill: parent
                        anchors.margins: Math.max(2, root.compactSpacing * 0.75)
                        spacing: root.compactSpacing

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: PresetLogic.describeAutoTrigger(rule.trigger)
                        }

                        StatusBadge {
                            text: ruleCard.isCurrentRule ? i18n("Current") : ""
                            fillColor: Qt.tint(Kirigami.Theme.highlightColor, Qt.rgba(1, 1, 1, 0.88))
                            textColor: Kirigami.Theme.highlightColor
                        }

                        QQC2.Switch {
                            checked: !!ruleCard.rule.enabled
                            enabled: !root.busy
                            text: ""
                            onClicked: root.autoRuleToggled(ruleCard.rule, checked)
                        }

                        PlasmaComponents3.ToolButton {
                            enabled: !root.busy
                            icon.name: "edit-delete"
                            text: i18n("Delete")
                            display: PlasmaComponents3.AbstractButton.IconOnly
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
