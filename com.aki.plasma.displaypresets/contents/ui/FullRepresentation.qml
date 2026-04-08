pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

import "code/DisplayPreset.js" as PresetLogic
import "code/Shell.js" as Shell

PlasmaExtras.Representation {
    id: root

    readonly property string translationDomain: "plasma_applet_com.aki.plasma.displaypresets"
    property var presets: []
    property var autoRules: []
    property var expandedPresetStates: ({})
    property var currentConnection: ({
        outputs: [],
        signature: "[]"
    })
    property string editingPresetId: ""
    property string renameDraft: ""
    property string statusText: ""
    property int statusType: Kirigami.MessageType.Information
    property string suggestedPresetName: ""
    property string observedConnectionSignature: ""
    property int observedConnectionCount: 0
    property string stableConnectionSignature: ""
    property string lastAutoAppliedSignature: ""
    property bool connectionDetectionReady: false
    readonly property bool isWaylandSession: String(Qt.platform.pluginName).toLowerCase().indexOf("wayland") >= 0
    readonly property bool busy: commandRunner.busy || autoRunner.busy
    readonly property bool autoEnabled: Plasmoid.configuration.autoEnabled
    readonly property bool hasCurrentConnection: !!(root.currentConnection && root.currentConnection.outputs && root.currentConnection.outputs.length > 0)
    readonly property string currentConnectionSignature: root.currentConnection ? root.currentConnection.signature : ""
    readonly property var currentMatchedRule: PresetLogic.findAutoRuleBySignature(root.autoRules, root.currentConnectionSignature)
    readonly property var currentEnabledRule: PresetLogic.findAutoRuleBySignature(root.autoRules, root.currentConnectionSignature, true)
    readonly property string currentConnectionDescription: root.hasCurrentConnection
        ? root.describeAutoTrigger(root.currentConnection)
        : i18nd(root.translationDomain, "No connected displays detected.")
    readonly property string currentConnectionStateText: root.autoEnabled
        ? (root.currentEnabledRule
            ? i18nd(root.translationDomain, "Will auto-apply: %1", root.presetNameForId(root.currentEnabledRule.presetId))
            : (root.currentMatchedRule
                ? i18nd(root.translationDomain, "Rule found, but it is currently disabled")
                : i18nd(root.translationDomain, "Current connection is not bound")))
        : i18nd(root.translationDomain, "Automatic restore is off")
    readonly property color currentConnectionStateFillColor: root.autoEnabled && root.currentEnabledRule
        ? Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(0, 0, 0, 0.18))
        : (root.autoEnabled && root.currentMatchedRule
            ? Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(0, 0, 0, 0.15))
            : Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.06)))
    readonly property color currentConnectionStateBorderColor: root.autoEnabled && root.currentEnabledRule
        ? Qt.tint(Kirigami.Theme.highlightColor, Qt.rgba(1, 1, 1, 0.15))
        : (root.autoEnabled && root.currentMatchedRule
            ? Qt.tint(Kirigami.Theme.textColor, Qt.rgba(1, 1, 1, 0.08))
            : Qt.rgba(0, 0, 0, 0))
    readonly property color currentConnectionStateTextColor: root.autoEnabled && root.currentEnabledRule
        ? Kirigami.Theme.textColor
        : (root.autoEnabled
            ? Kirigami.Theme.textColor
            : Kirigami.Theme.disabledTextColor)

    collapseMarginsHint: true
    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 24
    Layout.preferredWidth: Kirigami.Units.gridUnit * 26
    Layout.preferredHeight: Kirigami.Units.gridUnit * 28

    function defaultPresetName() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm");
    }

    function snapshotCommand() {
        return Shell.joinCommand(["kscreen-doctor", "-j"]);
    }

    function connectionOverviewCommand() {
        return Shell.joinCommand(["kscreen-doctor", "-o"]);
    }

    function displayLabel(output) {
        if (!output) {
            return i18nd(root.translationDomain, "Display");
        }

        return output.savedName || output.name || output.matchKey || output.connectorName || i18nd(root.translationDomain, "Display");
    }

    function describePresetSummary(preset) {
        var sanitizedPreset = PresetLogic.sanitizePreset(preset);
        if (!sanitizedPreset || sanitizedPreset.outputs.length === 0) {
            return "";
        }

        var enabledOutputs = [];
        for (var i = 0; i < sanitizedPreset.outputs.length; i += 1) {
            if (sanitizedPreset.outputs[i].enabled) {
                enabledOutputs.push(sanitizedPreset.outputs[i]);
            }
        }

        if (enabledOutputs.length === 0) {
            return i18nd(root.translationDomain, "All outputs disabled");
        }

        return enabledOutputs.map(function(output) {
            var parts = [];
            if (output.isPrimary) {
                parts.push(i18nd(root.translationDomain, "Primary"));
            }

            parts.push(root.displayLabel(output));

            if (output.modeToken) {
                parts.push(output.modeToken);
            }

            if (output.scale && Math.abs(output.scale - 1) > 0.001) {
                parts.push("x" + PresetLogic.formatScale(output.scale));
            }

            return parts.join(" ");
        }).join(" + ");
    }

    function describeAutoTrigger(trigger) {
        var normalized = PresetLogic.normalizeAutoTrigger(trigger);
        if (normalized.outputs.length === 0) {
            return "";
        }

        var parts = [];
        for (var i = 0; i < normalized.outputs.length; i += 1) {
            var output = normalized.outputs[i];
            var outputParts = [];

            outputParts.push(output.connectorName || i18nd(root.translationDomain, "Display"));
            if (output.type) {
                outputParts.push(output.type);
            }
            if (output.deviceUuid) {
                outputParts.push(PresetLogic.shortDeviceId(output.deviceUuid));
            }

            parts.push(outputParts.join(" "));
        }

        return parts.join(" + ");
    }

    function mergeContext(baseContext, extraContext) {
        var merged = {};
        var key;

        if (baseContext) {
            for (key in baseContext) {
                merged[key] = baseContext[key];
            }
        }

        if (extraContext) {
            for (key in extraContext) {
                merged[key] = extraContext[key];
            }
        }

        return merged;
    }

    function loadPresets() {
        root.presets = PresetLogic.parsePresets(Plasmoid.configuration.presetsJson);
        root.suggestedPresetName = root.defaultPresetName();
    }

    function loadAutoRules() {
        var parsedRules = PresetLogic.parseAutoRules(Plasmoid.configuration.autoRulesJson);
        var filteredRules = [];

        for (var i = 0; i < parsedRules.length; i += 1) {
            if (root.findPresetById(parsedRules[i].presetId)) {
                filteredRules.push(parsedRules[i]);
            }
        }

        root.autoRules = filteredRules;
        if (filteredRules.length !== parsedRules.length) {
            Plasmoid.configuration.autoRulesJson = PresetLogic.serializeAutoRules(filteredRules);
        }
    }

    function persistPresets(nextPresets) {
        root.presets = nextPresets;
        Plasmoid.configuration.presetsJson = PresetLogic.serializePresets(nextPresets);
    }

    function persistAutoRules(nextRules) {
        root.autoRules = nextRules;
        Plasmoid.configuration.autoRulesJson = PresetLogic.serializeAutoRules(nextRules);
    }

    function findPresetById(presetId) {
        for (var i = 0; i < root.presets.length; i += 1) {
            if (root.presets[i].id === presetId) {
                return root.presets[i];
            }
        }

        return null;
    }

    function presetNameForId(presetId) {
        var preset = root.findPresetById(presetId);
        return preset ? preset.name : i18nd(root.translationDomain, "Missing preset");
    }

    function autoRulesForPreset(presetId) {
        var rules = [];

        for (var i = 0; i < root.autoRules.length; i += 1) {
            if (root.autoRules[i].presetId === presetId) {
                rules.push(root.autoRules[i]);
            }
        }

        return rules;
    }

    function isPresetCurrentMatch(presetId) {
        return !!root.currentMatchedRule && root.currentMatchedRule.presetId === presetId;
    }

    function isRulesExpanded(presetId) {
        var key = String(presetId || "");
        if (root.expandedPresetStates[key] !== undefined) {
            return !!root.expandedPresetStates[key];
        }

        return root.isPresetCurrentMatch(presetId);
    }

    function setRulesExpanded(presetId, expanded) {
        var key = String(presetId || "");
        var nextState = {};
        var existingKey;

        for (existingKey in root.expandedPresetStates) {
            nextState[existingKey] = root.expandedPresetStates[existingKey];
        }

        nextState[key] = !!expanded;
        root.expandedPresetStates = nextState;
    }

    function toggleRulesExpanded(presetId) {
        root.setRulesExpanded(presetId, !root.isRulesExpanded(presetId));
    }

    function clearRulesExpanded(presetId) {
        var key = String(presetId || "");
        var nextState = {};
        var existingKey;

        for (existingKey in root.expandedPresetStates) {
            if (existingKey !== key) {
                nextState[existingKey] = root.expandedPresetStates[existingKey];
            }
        }

        root.expandedPresetStates = nextState;
    }

    function setStatus(type, text) {
        root.statusType = type;
        root.statusText = text;
        if (text.length > 0) {
            statusTimer.interval = type === Kirigami.MessageType.Error ? 12000 : 5000;
            statusTimer.restart();
        } else {
            statusTimer.stop();
        }
    }

    function clearEditState() {
        root.editingPresetId = "";
        root.renameDraft = "";
    }

    function summarizeCommandFailure(actionLabel, result) {
        var details = (result.stderr || result.stdout || "").trim();
        var suffix = details.length > 0 ? ": " + details.replace(/\s+/g, " ") : "";
        return actionLabel + " (" + result.exitCode + ")" + suffix;
    }

    function savePreset(existingPreset) {
        if (root.busy) {
            return;
        }

        var presetName = nameField.text.trim();
        if (existingPreset) {
            presetName = existingPreset.name;
        } else if (presetName.length === 0) {
            presetName = root.suggestedPresetName || root.defaultPresetName();
        }

        commandRunner.run(root.snapshotCommand(), {
            action: "save",
            name: presetName,
            existingId: existingPreset ? existingPreset.id : ""
        });
    }

    function runRestorePreparation(runner, presetId, origin, extraContext) {
        if (!presetId || !runner || runner.busy) {
            return false;
        }

        return runner.run(root.snapshotCommand(), root.mergeContext({
            action: "prepare-restore",
            presetId: presetId,
            origin: origin || "manual"
        }, extraContext));
    }

    function restorePreset(preset) {
        if (root.busy) {
            return;
        }

        root.runRestorePreparation(commandRunner, preset.id, "manual");
    }

    function bindCurrentConnectionToPreset(preset) {
        if (!preset || !root.hasCurrentConnection) {
            return;
        }

        var existingRule = PresetLogic.findAutoRuleBySignature(root.autoRules, root.currentConnection.signature);
        var nextRule = PresetLogic.createAutoRule(preset.id, root.currentConnection, {
            existingRule: existingRule,
            nowIso: new Date().toISOString()
        });

        if (!nextRule) {
            return;
        }

        root.persistAutoRules(PresetLogic.upsertAutoRule(root.autoRules, nextRule));
        root.setRulesExpanded(preset.id, true);

        if (root.autoEnabled && root.currentConnection.signature === nextRule.trigger.signature) {
            root.lastAutoAppliedSignature = "";
            root.maybeAutoApply(root.currentConnection);
        }

        root.setStatus(Kirigami.MessageType.Positive, existingRule
            ? i18nd(root.translationDomain, "Automatic rule updated.")
            : i18nd(root.translationDomain, "Automatic rule saved."));
    }

    function toggleAutoRule(rule, enabled) {
        root.persistAutoRules(PresetLogic.setAutoRuleEnabled(root.autoRules, rule.id, enabled, new Date().toISOString()));

        if (enabled && root.autoEnabled && root.currentConnection
                && rule.trigger.signature === root.currentConnection.signature) {
            root.lastAutoAppliedSignature = "";
            root.maybeAutoApply(root.currentConnection);
        }

        root.setStatus(Kirigami.MessageType.Positive, enabled
            ? i18nd(root.translationDomain, "Automatic rule enabled.")
            : i18nd(root.translationDomain, "Automatic rule disabled."));
    }

    function deleteAutoRule(rule) {
        root.persistAutoRules(PresetLogic.removeAutoRule(root.autoRules, rule.id));

        if (PresetLogic.countAutoRulesForPreset(root.autoRules, rule.presetId) <= 1) {
            root.clearRulesExpanded(rule.presetId);
        }

        root.setStatus(Kirigami.MessageType.Warning, i18nd(root.translationDomain, "Automatic rule deleted."));
    }

    function resetDetectionState() {
        root.observedConnectionSignature = "";
        root.observedConnectionCount = 0;
        root.stableConnectionSignature = "";
    }

    function pollCurrentConnection() {
        if (detectRunner.busy || root.busy) {
            return;
        }

        detectRunner.run(root.connectionOverviewCommand(), {
            action: "detect-connection"
        });
    }

    function handleDetectionResult(result) {
        if (result.exitCode !== 0) {
            return;
        }

        var nextConnection = PresetLogic.parseOutputOverview(result.stdout);
        root.currentConnection = nextConnection;
        root.observeConnection(nextConnection);
    }

    function observeConnection(connection) {
        var signature = connection && connection.signature ? connection.signature : "[]";

        if (signature !== root.observedConnectionSignature) {
            root.observedConnectionSignature = signature;
            root.observedConnectionCount = 1;
            return;
        }

        root.observedConnectionCount += 1;
        if (root.observedConnectionCount < 2) {
            return;
        }

        if (root.stableConnectionSignature === signature) {
            return;
        }

        root.stableConnectionSignature = signature;
        root.maybeAutoApply(connection);
    }

    function maybeAutoApply(connection) {
        if (!root.autoEnabled || !connection || !connection.signature) {
            return;
        }

        if (root.busy) {
            return;
        }

        if (root.lastAutoAppliedSignature === connection.signature) {
            return;
        }

        var rule = PresetLogic.findAutoRuleBySignature(root.autoRules, connection.signature, true);
        if (!rule) {
            return;
        }

        var preset = root.findPresetById(rule.presetId);
        if (!preset) {
            root.persistAutoRules(PresetLogic.removeAutoRule(root.autoRules, rule.id));
            root.setStatus(Kirigami.MessageType.Warning, i18nd(root.translationDomain, "An automatic rule referenced a preset that no longer exists and was removed."));
            return;
        }

        root.runRestorePreparation(autoRunner, preset.id, "auto", {
            connectionSignature: connection.signature,
            triggerDescription: root.describeAutoTrigger(connection)
        });
    }

    function handleSnapshotResult(runner, result, context) {
        if (result.exitCode !== 0) {
            var failureLabel = context.origin === "auto"
                ? i18nd(root.translationDomain, "Automatic restore snapshot failed")
                : i18nd(root.translationDomain, "kscreen-doctor snapshot failed");
            root.setStatus(Kirigami.MessageType.Error, root.summarizeCommandFailure(failureLabel, result));
            return;
        }

        var snapshot;
        try {
            snapshot = JSON.parse(result.stdout);
        } catch (error) {
            root.setStatus(Kirigami.MessageType.Error, i18nd(root.translationDomain, "Could not parse kscreen-doctor JSON output."));
            return;
        }

        if (context.action === "save") {
            var existingPreset = context.existingId ? root.findPresetById(context.existingId) : null;
            var preset = PresetLogic.createPreset(context.name, snapshot, {
                existingPreset: existingPreset,
                nowIso: new Date().toISOString()
            });

            if (!preset.outputs || preset.outputs.length === 0) {
                root.setStatus(Kirigami.MessageType.Error, i18nd(root.translationDomain, "No outputs were detected in the current display configuration."));
                return;
            }

            root.persistPresets(PresetLogic.upsertPreset(root.presets, preset));
            root.clearEditState();

            if (!existingPreset) {
                nameField.text = "";
            }

            root.suggestedPresetName = root.defaultPresetName();
            root.setStatus(Kirigami.MessageType.Positive, existingPreset
                ? i18nd(root.translationDomain, "Preset updated.")
                : i18nd(root.translationDomain, "Preset saved."));
            return;
        }

        if (context.action === "prepare-restore") {
            var presetToRestore = root.findPresetById(context.presetId);
            if (!presetToRestore) {
                root.setStatus(Kirigami.MessageType.Error, i18nd(root.translationDomain, "Preset not found."));
                return;
            }

            var restorePlan = PresetLogic.buildRestorePlan(presetToRestore, snapshot, {
                isWayland: root.isWaylandSession
            });

            if (restorePlan.args.length === 0) {
                root.setStatus(Kirigami.MessageType.Warning,
                    context.origin === "auto"
                        ? i18nd(root.translationDomain, "The automatic preset matched, but nothing could be restored.")
                        : i18nd(root.translationDomain, "Nothing could be restored from this preset."));
                return;
            }

            runner.run(Shell.joinCommand(["kscreen-doctor"].concat(restorePlan.args)), root.mergeContext(context, {
                action: "apply-restore",
                plan: restorePlan
            }));
        }
    }

    function handleRestoreResult(result, context) {
        if (result.exitCode !== 0) {
            var failureLabel = context.origin === "auto"
                ? i18nd(root.translationDomain, "Applying automatic preset failed")
                : i18nd(root.translationDomain, "Applying preset failed");
            root.setStatus(Kirigami.MessageType.Error, root.summarizeCommandFailure(failureLabel, result));
            return;
        }

        var plan = context.plan || {
            matchedCount: 0,
            missingOutputs: [],
            incompatibleModes: [],
            skippedScaleOutputs: [],
            primaryMissing: false
        };
        var notes = [];
        var severity = Kirigami.MessageType.Positive;

        if (plan.missingOutputs.length > 0) {
            notes.push(i18nd(root.translationDomain, "Missing: %1", plan.missingOutputs.join(", ")));
        }
        if (plan.incompatibleModes.length > 0) {
            notes.push(i18nd(root.translationDomain, "Unsupported mode: %1", plan.incompatibleModes.join(", ")));
        }
        if (plan.skippedScaleOutputs.length > 0) {
            notes.push(i18nd(root.translationDomain, "Scale skipped on this session: %1", plan.skippedScaleOutputs.join(", ")));
        }
        if (plan.primaryMissing) {
            notes.push(i18nd(root.translationDomain, "Primary output could not be restored."));
        }

        if (notes.length > 0) {
            severity = Kirigami.MessageType.Warning;
        }

        Plasmoid.configuration.lastUsedPresetId = context.presetId;
        if (context.origin === "auto" && context.connectionSignature) {
            root.lastAutoAppliedSignature = context.connectionSignature;
        }

        if (context.origin === "auto") {
            var triggerDescription = context.triggerDescription || i18nd(root.translationDomain, "current connection");
            var presetName = root.presetNameForId(context.presetId);
            root.setStatus(severity, notes.length > 0
                ? i18nd(root.translationDomain, "Automatically applied \"%1\" for %2. %3", presetName, triggerDescription, notes.join(" "))
                : i18nd(root.translationDomain, "Automatically applied \"%1\" for %2.", presetName, triggerDescription));
            return;
        }

        root.setStatus(severity, notes.length > 0
            ? i18ndp(root.translationDomain, "Restored %1 output. %2", "Restored %1 outputs. %2", plan.matchedCount, notes.join(" "))
            : i18ndp(root.translationDomain, "Restored %1 output.", "Restored %1 outputs.", plan.matchedCount));
    }

    function handleCommandFinished(runner, result, context) {
        if (!context || !context.action) {
            return;
        }

        if (context.action === "save" || context.action === "prepare-restore") {
            root.handleSnapshotResult(runner, result, context);
            return;
        }

        if (context.action === "apply-restore") {
            root.handleRestoreResult(result, context);
        }
    }

    function beginRename(preset) {
        if (root.busy) {
            return;
        }

        root.editingPresetId = preset.id;
        root.renameDraft = preset.name;
    }

    function commitRename(preset) {
        var nextName = root.renameDraft.trim();
        if (nextName.length === 0) {
            return;
        }

        root.persistPresets(PresetLogic.renamePreset(root.presets, preset.id, nextName, new Date().toISOString()));
        root.clearEditState();
        root.setStatus(Kirigami.MessageType.Positive, i18nd(root.translationDomain, "Preset renamed."));
    }

    function deletePreset(preset) {
        var nextPresets = PresetLogic.removePreset(root.presets, preset.id);
        var nextAutoRules = PresetLogic.removeAutoRulesForPreset(root.autoRules, preset.id);
        var removedRuleCount = root.autoRules.length - nextAutoRules.length;

        root.persistPresets(nextPresets);
        if (removedRuleCount > 0) {
            root.persistAutoRules(nextAutoRules);
        }

        root.clearRulesExpanded(preset.id);

        if (Plasmoid.configuration.lastUsedPresetId === preset.id) {
            Plasmoid.configuration.lastUsedPresetId = "";
        }

        root.clearEditState();
        root.setStatus(Kirigami.MessageType.Warning, removedRuleCount > 0
            ? i18ndp(root.translationDomain,
                "Preset deleted. Removed %1 automatic rule.",
                "Preset deleted. Removed %1 automatic rules.",
                removedRuleCount)
            : i18nd(root.translationDomain, "Preset deleted."));
    }

    onAutoEnabledChanged: {
        root.lastAutoAppliedSignature = "";
        root.resetDetectionState();
        root.pollCurrentConnection();
    }

    Component.onCompleted: {
        root.loadPresets();
        root.loadAutoRules();
        root.pollCurrentConnection();
    }

    CommandRunner {
        id: commandRunner
        onFinished: function(result, context) {
            root.handleCommandFinished(commandRunner, result, context);
        }
    }

    CommandRunner {
        id: detectRunner
        onFinished: function(result, context) {
            if (context && context.action === "detect-connection") {
                root.connectionDetectionReady = true;
                root.handleDetectionResult(result);
            }
        }
    }

    CommandRunner {
        id: autoRunner
        onFinished: function(result, context) {
            root.handleCommandFinished(autoRunner, result, context);
        }
    }

    Timer {
        id: statusTimer
        interval: 5000
        repeat: false
        onTriggered: root.statusText = ""
    }

    Timer {
        id: connectionPollTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.pollCurrentConnection()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.max(3, Kirigami.Units.smallSpacing * 0.65)

        Rectangle {
            Layout.fillWidth: true
            radius: Kirigami.Units.cornerRadius
            color: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.04))
            border.width: 1
            border.color: root.currentEnabledRule
                ? Kirigami.Theme.highlightColor
                : Qt.tint(Kirigami.Theme.textColor, Qt.rgba(0, 0, 0, 0.78))
            implicitHeight: statusCardContent.implicitHeight + (Kirigami.Units.smallSpacing * 2)

            ColumnLayout {
                id: statusCardContent
                anchors.fill: parent
                anchors.margins: Math.max(4, Kirigami.Units.smallSpacing * 0.7)
                spacing: Math.max(3, Kirigami.Units.smallSpacing * 0.65)

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        font.weight: Font.DemiBold
                        text: i18nd(root.translationDomain, "Current Connection")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    QQC2.BusyIndicator {
                        running: detectRunner.busy
                        visible: running && !root.connectionDetectionReady
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: Kirigami.Units.iconSizes.small
                    }

                    QQC2.Switch {
                        checked: root.autoEnabled
                        text: i18nd(root.translationDomain, "Memory Mode")
                        onClicked: Plasmoid.configuration.autoEnabled = checked
                    }
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: root.currentConnectionDescription
                }

                StatusBadge {
                    Layout.alignment: Qt.AlignLeft
                    fillColor: root.currentConnectionStateFillColor
                    borderColor: root.currentConnectionStateBorderColor
                    text: root.currentConnectionStateText
                    textColor: root.currentConnectionStateTextColor
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.max(3, Kirigami.Units.smallSpacing * 0.65)

            QQC2.TextField {
                id: nameField
                Layout.fillWidth: true
                enabled: !root.busy
                placeholderText: root.suggestedPresetName
                selectByMouse: true
                onAccepted: root.savePreset(null)
            }

            PlasmaComponents3.Button {
                id: saveButton
                enabled: !root.busy
                icon.name: "document-save"
                text: i18nd(root.translationDomain, "Save Layout")
                leftPadding: Math.max(4, Kirigami.Units.smallSpacing * 0.8)
                rightPadding: Math.max(4, Kirigami.Units.smallSpacing * 0.8)
                topPadding: 2
                bottomPadding: 2
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                onClicked: root.savePreset(null)
            }

            QQC2.BusyIndicator {
                Layout.alignment: Qt.AlignVCenter
                running: root.busy
                visible: running
            }
        }

        Kirigami.InlineMessage {
            id: statusMessage
            Layout.fillWidth: true
            text: root.statusText
            type: root.statusType
            visible: root.statusText.length > 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Flickable {
                id: scrollArea
                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentWidth: width
                contentHeight: contentColumn.implicitHeight
                interactive: contentHeight > height

                Column {
                    id: contentColumn
                    width: scrollArea.width
                    spacing: Math.max(3, Kirigami.Units.smallSpacing * 0.65)

                    RowLayout {
                        width: parent.width

                        PlasmaComponents3.Label {
                            font.weight: Font.DemiBold
                            text: i18nd(root.translationDomain, "Presets")
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StatusBadge {
                            text: root.presets.length > 0
                                ? i18ndp(root.translationDomain, "%1 saved layout", "%1 saved layouts", root.presets.length)
                                : ""
                            fillColor: Qt.tint(Kirigami.Theme.backgroundColor, Qt.rgba(1, 1, 1, 0.08))
                            textColor: Kirigami.Theme.disabledTextColor
                        }
                    }

                    Repeater {
                        model: root.presets

                        delegate: Item {
                            required property var modelData

                            width: contentColumn.width
                            height: presetDelegate.implicitHeight

                            PresetDelegate {
                                id: presetDelegate
                                anchors.left: parent.left
                                anchors.right: parent.right
                                autoBindingAvailable: root.hasCurrentConnection
                                autoRuleCount: PresetLogic.countAutoRulesForPreset(root.autoRules, preset.id)
                                autoRules: root.autoRulesForPreset(preset.id)
                                busy: root.busy
                                currentConnectionBound: root.isPresetCurrentMatch(preset.id)
                                currentConnectionSignature: root.currentConnectionSignature
                                formatAutoTrigger: root.describeAutoTrigger
                                formatPresetSummary: root.describePresetSummary
                                isEditing: root.editingPresetId === preset.id
                                isLastUsed: Plasmoid.configuration.lastUsedPresetId === preset.id
                                preset: parent.modelData
                                renameText: root.editingPresetId === preset.id ? root.renameDraft : (preset.name || "")
                                rulesExpanded: root.isRulesExpanded(preset.id)

                                onBeginRename: root.beginRename(preset)
                                onRenameInputEdited: function(text) {
                                    if (root.editingPresetId === preset.id) {
                                        root.renameDraft = text;
                                    }
                                }
                                onCommitRename: root.commitRename(preset)
                                onCancelRename: root.clearEditState()
                                onRestoreClicked: root.restorePreset(preset)
                                onBindAutoClicked: root.bindCurrentConnectionToPreset(preset)
                                onOverwriteClicked: root.savePreset(preset)
                                onDeleteClicked: root.deletePreset(preset)
                                onToggleRulesExpanded: root.toggleRulesExpanded(preset.id)
                                onAutoRuleToggled: function(rule, enabled) {
                                    root.toggleAutoRule(rule, enabled);
                                }
                                onAutoRuleDeleted: function(rule) {
                                    root.deleteAutoRule(rule);
                                }
                            }
                        }
                    }

                    PlasmaExtras.PlaceholderMessage {
                        width: Math.min(Math.max(parent.width - (Kirigami.Units.gridUnit * 2), 0), Kirigami.Units.gridUnit * 18)
                        visible: root.presets.length === 0
                        iconName: "video-display"
                        text: i18nd(root.translationDomain, "No saved layouts yet")
                        explanation: i18nd(root.translationDomain, "Save your current monitor setup here, then restore it later with one click.")
                    }
                }
            }
        }
    }
}
