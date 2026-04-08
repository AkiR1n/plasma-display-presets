import QtQuick 2.15
import QtTest 1.2

import "../com.aki.plasma.displaypresets/contents/ui/code/DisplayPreset.js" as PresetLogic
import "../com.aki.plasma.displaypresets/contents/ui/code/Shell.js" as Shell

TestCase {
    name: "DisplayPresetLogic"

    function test_parsePresets_invalidJson_returnsEmptyArray() {
        compare(PresetLogic.parsePresets("{").length, 0);
    }

    function test_normalizeSnapshot_derivesPrimaryAndModeTokens() {
        var snapshot = {
            outputs: {
                a: {
                    id: 11,
                    name: "eDP-1",
                    hashMd5: "hash-edp",
                    enabled: true,
                    priority: 1,
                    pos: { x: 0, y: 0 },
                    scale: 1,
                    rotation: 1,
                    currentModeId: "m1",
                    modes: {
                        m1: {
                            id: "m1",
                            name: "1920x1080@60"
                        }
                    }
                },
                b: {
                    id: 12,
                    name: "DP-1",
                    hashMd5: "hash-dp",
                    enabled: true,
                    priority: 2,
                    pos: { x: 1920, y: 0 },
                    scale: 1.25,
                    rotation: 2,
                    currentModeId: "m2",
                    modes: {
                        m2: {
                            id: "m2",
                            size: { width: 2560, height: 1440 },
                            refreshRate: 59.95
                        }
                    }
                }
            }
        };

        var normalized = PresetLogic.normalizeSnapshot(snapshot);

        compare(normalized.outputs.length, 2);
        compare(normalized.outputs[0].name, "eDP-1");
        compare(normalized.outputs[0].isPrimary, true);
        compare(normalized.outputs[0].modeToken, "1920x1080@60");
        compare(normalized.outputs[1].rotation, "left");
        compare(normalized.outputs[1].modeToken, "2560x1440@59.95");
        compare(normalized.outputs[1].scale, 1.25);
    }

    function test_buildRestorePlan_usesLiveIds_andKeepsWarnings() {
        var preset = {
            id: "preset-1",
            name: "Desk",
            createdAt: "2026-04-07T10:00:00Z",
            updatedAt: "2026-04-07T10:00:00Z",
            outputs: [
                {
                    matchKey: "hash-edp",
                    savedName: "eDP-1",
                    enabled: true,
                    isPrimary: true,
                    priority: 1,
                    position: { x: 0, y: 0 },
                    scale: 1.25,
                    rotation: "none",
                    modeToken: "1920x1080@60"
                },
                {
                    matchKey: "hash-missing",
                    savedName: "HDMI-A-1",
                    enabled: true,
                    isPrimary: false,
                    priority: 2,
                    position: { x: 1920, y: 0 },
                    scale: 1,
                    rotation: "right",
                    modeToken: "3840x2160@60"
                }
            ]
        };

        var liveSnapshot = {
            outputs: [
                {
                    id: 41,
                    name: "eDP-1",
                    hashMd5: "hash-edp",
                    enabled: true,
                    priority: 1,
                    pos: { x: 0, y: 0 },
                    scale: 1,
                    rotation: 1,
                    currentModeId: "live-1",
                    modes: [
                        { id: "live-1", name: "1920x1080@60" }
                    ]
                }
            ]
        };

        var plan = PresetLogic.buildRestorePlan(preset, liveSnapshot, {
            isWayland: true
        });

        compare(plan.matchedCount, 1);
        compare(plan.missingOutputs.length, 1);
        verify(plan.args.indexOf("output.41.enable") >= 0);
        verify(plan.args.indexOf("output.41.mode.1920x1080@60") >= 0);
        verify(plan.args.indexOf("output.41.position.0,0") >= 0);
        verify(plan.args.indexOf("output.41.scale.1.25") >= 0);
        compare(plan.args[plan.args.length - 1], "output.41.primary");
    }

    function test_buildRestorePlan_skipsScaleOnX11() {
        var preset = {
            id: "preset-2",
            name: "Desk",
            createdAt: "2026-04-07T10:00:00Z",
            updatedAt: "2026-04-07T10:00:00Z",
            outputs: [
                {
                    matchKey: "hash-edp",
                    savedName: "eDP-1",
                    enabled: true,
                    isPrimary: true,
                    priority: 1,
                    position: { x: 0, y: 0 },
                    scale: 1.5,
                    rotation: "none",
                    modeToken: "1920x1080@60"
                }
            ]
        };

        var liveSnapshot = {
            outputs: [
                {
                    id: 21,
                    name: "eDP-1",
                    hashMd5: "hash-edp",
                    enabled: true,
                    priority: 1,
                    currentModeId: "live-1",
                    modes: [
                        { id: "live-1", name: "1920x1080@60" }
                    ]
                }
            ]
        };

        var plan = PresetLogic.buildRestorePlan(preset, liveSnapshot, {
            isWayland: false
        });

        compare(plan.skippedScaleOutputs.length, 1);
        verify(plan.args.indexOf("output.21.scale.1.5") === -1);
    }

    function test_shellJoin_quotesSingleQuotes() {
        compare(
            Shell.joinCommand(["kscreen-doctor", "output.1.iccprofile./tmp/o'neil.icc"]),
            "'kscreen-doctor' 'output.1.iccprofile./tmp/o'\"'\"'neil.icc'"
        );
    }

    function test_parseOutputOverview_extractsConnectedDisplaysAndSignature() {
        var overview = "\u001b[01;32mOutput: \u001b[0;0m1 eDP-2 af2a9470-1224-40bb-9ded-ada4825afb38\n"
            + "\tenabled\n"
            + "\tconnected\n"
            + "\tPanel\n"
            + "\u001b[01;32mOutput: \u001b[0;0m2 DP-3 5b247e79-bdb3-4d8e-be63-8ac20b280812\n"
            + "\tenabled\n"
            + "\tconnected\n"
            + "\tDisplayPort\n"
            + "Output: 3 HDMI-A-1 missing-device\n"
            + "\tdisabled\n"
            + "\tdisconnected\n"
            + "\tHDMI\n";

        var parsed = PresetLogic.parseOutputOverview(overview);

        compare(parsed.outputs.length, 2);
        compare(parsed.outputs[0].connectorName, "DP-3");
        compare(parsed.outputs[0].deviceUuid, "5b247e79-bdb3-4d8e-be63-8ac20b280812");
        compare(parsed.outputs[0].type, "DisplayPort");
        compare(parsed.outputs[1].connectorName, "eDP-2");
        compare(parsed.signature, JSON.stringify([
            ["DP-3", "5b247e79-bdb3-4d8e-be63-8ac20b280812", "DisplayPort"],
            ["eDP-2", "af2a9470-1224-40bb-9ded-ada4825afb38", "Panel"]
        ]));
    }

    function test_autoRules_replaceSameSignatureAndDifferentConnectorDoesNotMatch() {
        var dp3Connection = {
            outputs: [
                {
                    connectorName: "eDP-2",
                    deviceUuid: "internal-panel",
                    type: "Panel"
                },
                {
                    connectorName: "DP-3",
                    deviceUuid: "desk-monitor",
                    type: "DisplayPort"
                }
            ]
        };
        var dp4Connection = {
            outputs: [
                {
                    connectorName: "eDP-2",
                    deviceUuid: "internal-panel",
                    type: "Panel"
                },
                {
                    connectorName: "DP-4",
                    deviceUuid: "desk-monitor",
                    type: "DisplayPort"
                }
            ]
        };

        var firstRule = PresetLogic.createAutoRule("preset-a", dp3Connection, {
            nowIso: "2026-04-08T10:00:00Z"
        });
        var rules = PresetLogic.upsertAutoRule([], firstRule);
        var replacementRule = PresetLogic.createAutoRule("preset-b", dp3Connection, {
            nowIso: "2026-04-08T10:05:00Z"
        });

        rules = PresetLogic.upsertAutoRule(rules, replacementRule);

        compare(rules.length, 1);
        compare(rules[0].presetId, "preset-b");
        compare(PresetLogic.findAutoRuleBySignature(rules, firstRule.trigger.signature).presetId, "preset-b");
        compare(PresetLogic.findAutoRuleBySignature(rules, PresetLogic.normalizeAutoTrigger(dp4Connection).signature), null);
    }

    function test_removeAutoRulesForPreset_removesLinkedRulesOnly() {
        var internalOnly = PresetLogic.createAutoRule("preset-internal", {
            outputs: [
                {
                    connectorName: "eDP-2",
                    deviceUuid: "internal-panel",
                    type: "Panel"
                }
            ]
        }, {
            nowIso: "2026-04-08T11:00:00Z"
        });
        var docked = PresetLogic.createAutoRule("preset-docked", {
            outputs: [
                {
                    connectorName: "eDP-2",
                    deviceUuid: "internal-panel",
                    type: "Panel"
                },
                {
                    connectorName: "DP-3",
                    deviceUuid: "desk-monitor",
                    type: "DisplayPort"
                }
            ]
        }, {
            nowIso: "2026-04-08T11:05:00Z"
        });

        var rules = PresetLogic.removeAutoRulesForPreset([internalOnly, docked], "preset-internal");

        compare(rules.length, 1);
        compare(rules[0].presetId, "preset-docked");
    }
}
