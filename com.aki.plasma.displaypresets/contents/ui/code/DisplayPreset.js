.pragma library

var ROTATION_BY_VALUE = {
    1: "none",
    2: "left",
    4: "inverted",
    8: "right",
    16: "flipped",
    32: "flipped90",
    64: "flipped180",
    128: "flipped270"
};

var ROTATION_TOKENS = {
    "none": true,
    "left": true,
    "right": true,
    "inverted": true,
    "flipped": true,
    "flipped90": true,
    "flipped180": true,
    "flipped270": true
};

function parsePresets(jsonText) {
    if (jsonText === undefined || jsonText === null || String(jsonText).trim() === "") {
        return [];
    }

    try {
        var parsed = JSON.parse(jsonText);
        if (!Array.isArray(parsed)) {
            return [];
        }

        var sanitized = [];
        for (var i = 0; i < parsed.length; i += 1) {
            var preset = sanitizePreset(parsed[i]);
            if (preset) {
                sanitized.push(preset);
            }
        }

        return sortPresets(sanitized);
    } catch (error) {
        return [];
    }
}

function serializePresets(presets) {
    return JSON.stringify(sortPresets(presets || []));
}

function parseAutoRules(jsonText) {
    if (jsonText === undefined || jsonText === null || String(jsonText).trim() === "") {
        return [];
    }

    try {
        var parsed = JSON.parse(jsonText);
        if (!Array.isArray(parsed)) {
            return [];
        }

        var sanitized = [];
        for (var i = 0; i < parsed.length; i += 1) {
            var rule = sanitizeAutoRule(parsed[i]);
            if (rule) {
                sanitized.push(rule);
            }
        }

        return sortAutoRules(sanitized);
    } catch (error) {
        return [];
    }
}

function serializeAutoRules(rules) {
    return JSON.stringify(sortAutoRules(rules || []));
}

function upsertPreset(presets, preset) {
    var next = [];
    var target = sanitizePreset(preset);

    if (!target) {
        return sortPresets(presets || []);
    }

    var current = Array.isArray(presets) ? presets : [];
    for (var i = 0; i < current.length; i += 1) {
        if (current[i] && current[i].id !== target.id) {
            next.push(sanitizePreset(current[i]));
        }
    }

    next.push(target);
    return sortPresets(next.filter(Boolean));
}

function renamePreset(presets, presetId, newName, nowIso) {
    var next = [];
    var current = Array.isArray(presets) ? presets : [];
    var trimmed = cleanName(newName);

    for (var i = 0; i < current.length; i += 1) {
        var preset = sanitizePreset(current[i]);
        if (!preset) {
            continue;
        }

        if (preset.id === presetId) {
            preset.name = trimmed || preset.name;
            preset.updatedAt = nowIso || preset.updatedAt;
        }

        next.push(preset);
    }

    return sortPresets(next);
}

function removePreset(presets, presetId) {
    var next = [];
    var current = Array.isArray(presets) ? presets : [];

    for (var i = 0; i < current.length; i += 1) {
        var preset = sanitizePreset(current[i]);
        if (preset && preset.id !== presetId) {
            next.push(preset);
        }
    }

    return sortPresets(next);
}

function createAutoRule(presetId, connection, options) {
    var trigger = normalizeAutoTrigger(connection);
    var existingRule = options && options.existingRule ? sanitizeAutoRule(options.existingRule) : null;
    var nowIso = options && options.nowIso ? String(options.nowIso) : new Date().toISOString();

    if (!presetId || trigger.outputs.length === 0) {
        return null;
    }

    return {
        id: existingRule && existingRule.id ? existingRule.id : generateId("rule-" + nowIso),
        presetId: String(presetId),
        enabled: true,
        createdAt: existingRule && existingRule.createdAt ? existingRule.createdAt : nowIso,
        updatedAt: nowIso,
        trigger: {
            outputs: trigger.outputs,
            signature: trigger.signature
        }
    };
}

function upsertAutoRule(rules, rule) {
    var next = [];
    var target = sanitizeAutoRule(rule);
    var current = Array.isArray(rules) ? rules : [];

    if (!target) {
        return sortAutoRules(current);
    }

    for (var i = 0; i < current.length; i += 1) {
        var existingRule = sanitizeAutoRule(current[i]);
        if (!existingRule) {
            continue;
        }

        if (existingRule.id === target.id) {
            continue;
        }

        if (existingRule.trigger.signature === target.trigger.signature) {
            continue;
        }

        next.push(existingRule);
    }

    next.push(target);
    return sortAutoRules(next);
}

function setAutoRuleEnabled(rules, ruleId, enabled, nowIso) {
    var next = [];
    var current = Array.isArray(rules) ? rules : [];

    for (var i = 0; i < current.length; i += 1) {
        var rule = sanitizeAutoRule(current[i]);
        if (!rule) {
            continue;
        }

        if (rule.id === ruleId) {
            rule.enabled = !!enabled;
            rule.updatedAt = nowIso || rule.updatedAt;
        }

        next.push(rule);
    }

    return sortAutoRules(next);
}

function removeAutoRule(rules, ruleId) {
    var next = [];
    var current = Array.isArray(rules) ? rules : [];

    for (var i = 0; i < current.length; i += 1) {
        var rule = sanitizeAutoRule(current[i]);
        if (rule && rule.id !== ruleId) {
            next.push(rule);
        }
    }

    return sortAutoRules(next);
}

function removeAutoRulesForPreset(rules, presetId) {
    var next = [];
    var current = Array.isArray(rules) ? rules : [];

    for (var i = 0; i < current.length; i += 1) {
        var rule = sanitizeAutoRule(current[i]);
        if (rule && rule.presetId !== presetId) {
            next.push(rule);
        }
    }

    return sortAutoRules(next);
}

function countAutoRulesForPreset(rules, presetId) {
    var count = 0;
    var current = Array.isArray(rules) ? rules : [];

    for (var i = 0; i < current.length; i += 1) {
        var rule = sanitizeAutoRule(current[i]);
        if (rule && rule.presetId === presetId) {
            count += 1;
        }
    }

    return count;
}

function findAutoRuleBySignature(rules, signature, enabledOnly) {
    if (!signature) {
        return null;
    }

    var current = Array.isArray(rules) ? rules : [];
    for (var i = 0; i < current.length; i += 1) {
        var rule = sanitizeAutoRule(current[i]);
        if (!rule) {
            continue;
        }

        if (!!enabledOnly && !rule.enabled) {
            continue;
        }

        if (rule.trigger.signature === signature) {
            return rule;
        }
    }

    return null;
}

function createPreset(name, snapshot, options) {
    var normalizedSnapshot = normalizeSnapshot(snapshot);
    var existingPreset = options && options.existingPreset ? sanitizePreset(options.existingPreset) : null;
    var nowIso = options && options.nowIso ? String(options.nowIso) : new Date().toISOString();
    var presetName = cleanName(name) || (existingPreset ? existingPreset.name : "Display preset");
    var outputs = [];

    for (var i = 0; i < normalizedSnapshot.outputs.length; i += 1) {
        outputs.push(toStoredOutput(normalizedSnapshot.outputs[i]));
    }

    return {
        id: existingPreset && existingPreset.id ? existingPreset.id : generateId(nowIso),
        name: presetName,
        createdAt: existingPreset && existingPreset.createdAt ? existingPreset.createdAt : nowIso,
        updatedAt: nowIso,
        outputs: outputs
    };
}

function normalizeSnapshot(snapshot) {
    var rawOutputs = extractOutputs(snapshot);
    var normalized = [];

    for (var i = 0; i < rawOutputs.length; i += 1) {
        var output = normalizeOutput(rawOutputs[i]);
        if (output) {
            normalized.push(output);
        }
    }

    normalized.sort(compareOutputsForDisplay);

    var primaryOutput = findPrimaryOutput(normalized);
    for (var j = 0; j < normalized.length; j += 1) {
        normalized[j].isPrimary = !!primaryOutput && normalized[j].matchKey === primaryOutput.matchKey;
    }

    return {
        outputs: normalized
    };
}

function buildRestorePlan(preset, liveSnapshot, options) {
    var sanitizedPreset = sanitizePreset(preset);
    var liveOutputs = normalizeSnapshot(liveSnapshot).outputs;
    var isWayland = options && options.isWayland !== undefined ? !!options.isWayland : true;
    var liveByKey = {};
    var liveByName = {};
    var usedKeys = {};
    var matched = [];
    var missingOutputs = [];
    var incompatibleModes = [];
    var skippedScaleOutputs = [];
    var args = [];
    var primaryTarget = null;
    var hasPrimaryOutput = false;
    var primaryMissing = false;

    if (!sanitizedPreset) {
        return {
            args: [],
            matchedCount: 0,
            missingOutputs: [],
            incompatibleModes: [],
            skippedScaleOutputs: [],
            primaryMissing: false
        };
    }

    for (var i = 0; i < liveOutputs.length; i += 1) {
        pushIndex(liveByKey, liveOutputs[i].matchKey, liveOutputs[i]);
        pushIndex(liveByName, liveOutputs[i].name, liveOutputs[i]);
    }

    for (var j = 0; j < sanitizedPreset.outputs.length; j += 1) {
        var presetOutput = sanitizedPreset.outputs[j];
        var liveOutput = takeMatch(liveByKey, presetOutput.matchKey, usedKeys);

        if (!liveOutput) {
            liveOutput = takeMatch(liveByName, presetOutput.savedName, usedKeys);
        }

        if (!liveOutput) {
            missingOutputs.push(describeOutput(presetOutput));
            if (presetOutput.isPrimary) {
                primaryMissing = true;
            }
            continue;
        }

        matched.push({
            preset: presetOutput,
            live: liveOutput
        });
    }

    matched.sort(compareMatchedOutputs);

    for (var k = 0; k < matched.length; k += 1) {
        var pair = matched[k];
        var address = outputAddress(pair.live);

        if (!address) {
            continue;
        }

        if (pair.preset.isPrimary) {
            hasPrimaryOutput = true;
        }

        if (pair.preset.enabled) {
            args.push("output." + address + ".enable");

            if (pair.preset.modeToken) {
                if (pair.live.availableModeTokens.length === 0 || pair.live.availableModeTokens.indexOf(pair.preset.modeToken) >= 0) {
                    args.push("output." + address + ".mode." + pair.preset.modeToken);
                } else {
                    incompatibleModes.push(describeOutput(pair.preset) + " (" + pair.preset.modeToken + ")");
                }
            }

            args.push("output." + address + ".rotation." + pair.preset.rotation);

            if (pair.preset.position) {
                args.push("output." + address + ".position." + pair.preset.position.x + "," + pair.preset.position.y);
            }

            if (pair.preset.isPrimary) {
                primaryTarget = address;
            }

            if (shouldApplyScale(pair.preset.scale)) {
                if (isWayland) {
                    args.push("output." + address + ".scale." + formatScale(pair.preset.scale));
                } else {
                    skippedScaleOutputs.push(describeOutput(pair.preset));
                }
            }
        } else {
            args.push("output." + address + ".disable");
            if (pair.preset.isPrimary) {
                primaryMissing = true;
            }
        }
    }

    if (primaryTarget) {
        args.push("output." + primaryTarget + ".primary");
    } else if (hasPrimaryOutput) {
        primaryMissing = true;
    }

    return {
        args: args,
        matchedCount: matched.length,
        missingOutputs: missingOutputs,
        incompatibleModes: incompatibleModes,
        skippedScaleOutputs: skippedScaleOutputs,
        primaryMissing: primaryMissing
    };
}

function describePreset(preset) {
    var sanitizedPreset = sanitizePreset(preset);
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
        return "All outputs disabled";
    }

    return enabledOutputs.map(function(output) {
        var parts = [];
        if (output.isPrimary) {
            parts.push("Primary");
        }
        parts.push(output.savedName || "Display");
        if (output.modeToken) {
            parts.push(output.modeToken);
        }
        if (output.scale && Math.abs(output.scale - 1) > 0.001) {
            parts.push("x" + formatScale(output.scale));
        }
        return parts.join(" ");
    }).join(" + ");
}

function parseOutputOverview(text) {
    var stripped = stripAnsi(text || "");
    var lines = String(stripped).replace(/\r\n?/g, "\n").split("\n");
    var outputs = [];
    var currentOutput = null;

    for (var i = 0; i < lines.length; i += 1) {
        var trimmed = String(lines[i] || "").trim();
        if (!trimmed) {
            continue;
        }

        if (trimmed.indexOf("Output:") === 0) {
            if (currentOutput) {
                outputs.push(currentOutput);
            }

            currentOutput = parseOutputOverviewHeader(trimmed);
            continue;
        }

        if (!currentOutput) {
            continue;
        }

        if (trimmed === "connected") {
            currentOutput.connected = true;
            continue;
        }

        if (trimmed === "disconnected") {
            currentOutput.connected = false;
            continue;
        }

        if (trimmed === "enabled") {
            currentOutput.enabled = true;
            continue;
        }

        if (trimmed === "disabled") {
            currentOutput.enabled = false;
            continue;
        }

        if (!currentOutput.type && isOutputTypeLine(trimmed)) {
            currentOutput.type = trimmed;
        }
    }

    if (currentOutput) {
        outputs.push(currentOutput);
    }

    var connectedOutputs = [];
    for (var j = 0; j < outputs.length; j += 1) {
        if (outputs[j].connected) {
            connectedOutputs.push(outputs[j]);
        }
    }

    return normalizeAutoTrigger({
        outputs: connectedOutputs
    });
}

function describeAutoTrigger(trigger) {
    var normalized = normalizeAutoTrigger(trigger);
    if (normalized.outputs.length === 0) {
        return "";
    }

    var parts = [];
    for (var i = 0; i < normalized.outputs.length; i += 1) {
        var output = normalized.outputs[i];
        var outputParts = [];

        outputParts.push(output.connectorName || "Display");
        if (output.type) {
            outputParts.push(output.type);
        }
        if (output.deviceUuid) {
            outputParts.push(shortDeviceId(output.deviceUuid));
        }

        parts.push(outputParts.join(" "));
    }

    return parts.join(" + ");
}

function sanitizePreset(rawPreset) {
    if (!rawPreset || typeof rawPreset !== "object") {
        return null;
    }

    var outputs = [];
    var rawOutputs = Array.isArray(rawPreset.outputs) ? rawPreset.outputs : [];
    for (var i = 0; i < rawOutputs.length; i += 1) {
        var output = sanitizeStoredOutput(rawOutputs[i]);
        if (output) {
            outputs.push(output);
        }
    }

    outputs.sort(compareStoredOutputs);

    if (outputs.length === 0) {
        return null;
    }

    return {
        id: firstString([rawPreset.id]) || generateId(rawPreset.updatedAt),
        name: cleanName(rawPreset.name) || "Display preset",
        createdAt: firstString([rawPreset.createdAt]) || firstString([rawPreset.updatedAt]) || new Date().toISOString(),
        updatedAt: firstString([rawPreset.updatedAt]) || firstString([rawPreset.createdAt]) || new Date().toISOString(),
        outputs: outputs
    };
}

function sanitizeAutoRule(rawRule) {
    if (!rawRule || typeof rawRule !== "object") {
        return null;
    }

    var trigger = normalizeAutoTrigger(rawRule.trigger || rawRule.connection || rawRule);
    var presetId = firstString([rawRule.presetId]);

    if (!presetId || trigger.outputs.length === 0) {
        return null;
    }

    return {
        id: firstString([rawRule.id]) || generateId(rawRule.updatedAt),
        presetId: presetId,
        enabled: toBoolean(rawRule.enabled, true),
        createdAt: firstString([rawRule.createdAt]) || firstString([rawRule.updatedAt]) || new Date().toISOString(),
        updatedAt: firstString([rawRule.updatedAt]) || firstString([rawRule.createdAt]) || new Date().toISOString(),
        trigger: {
            outputs: trigger.outputs,
            signature: trigger.signature
        }
    };
}

function sanitizeStoredOutput(rawOutput) {
    if (!rawOutput || typeof rawOutput !== "object") {
        return null;
    }

    var savedName = firstString([rawOutput.savedName, rawOutput.name]);
    var matchKey = firstString([rawOutput.matchKey, savedName]);

    if (!savedName && !matchKey) {
        return null;
    }

    return {
        matchKey: matchKey,
        savedName: savedName || matchKey,
        enabled: toBoolean(rawOutput.enabled, true),
        isPrimary: toBoolean(rawOutput.isPrimary, false),
        priority: positiveNumber(rawOutput.priority, 0),
        position: parsePoint(rawOutput.position),
        scale: sanitizeScale(rawOutput.scale),
        rotation: normalizeRotation(rawOutput.rotation),
        modeToken: sanitizeModeToken(rawOutput.modeToken)
    };
}

function toStoredOutput(output) {
    return {
        matchKey: output.matchKey,
        savedName: output.name,
        enabled: output.enabled,
        isPrimary: output.isPrimary,
        priority: output.priority,
        position: output.position,
        scale: output.scale,
        rotation: output.rotation,
        modeToken: output.modeToken
    };
}

function normalizeAutoTrigger(rawTrigger) {
    var rawOutputs = [];
    var outputs = [];

    if (Array.isArray(rawTrigger)) {
        rawOutputs = rawTrigger;
    } else if (rawTrigger && Array.isArray(rawTrigger.outputs)) {
        rawOutputs = rawTrigger.outputs;
    } else if (rawTrigger && rawTrigger.outputs) {
        rawOutputs = objectValues(rawTrigger.outputs);
    }

    for (var i = 0; i < rawOutputs.length; i += 1) {
        var output = sanitizeTriggerOutput(rawOutputs[i]);
        if (output) {
            outputs.push(output);
        }
    }

    outputs.sort(compareTriggerOutputs);

    return {
        outputs: outputs,
        signature: buildConnectionSignature(outputs)
    };
}

function extractOutputs(snapshot) {
    var candidates = [
        snapshot && snapshot.outputs,
        snapshot && snapshot.config && snapshot.config.outputs,
        snapshot && snapshot.config && snapshot.config.connectedOutputs
    ];

    for (var i = 0; i < candidates.length; i += 1) {
        var candidate = candidates[i];
        var values = objectValues(candidate);
        if (values.length > 0) {
            return values;
        }
    }

    return [];
}

function normalizeOutput(rawOutput) {
    if (!rawOutput || typeof rawOutput !== "object") {
        return null;
    }

    var id = nullableNumber(rawOutput.id);
    var name = firstString([rawOutput.name, rawOutput.connector]);
    var matchKey = firstString([
        rawOutput.hashMd5,
        rawOutput.hash,
        rawOutput.edid && rawOutput.edid.hashMd5,
        rawOutput.edid && rawOutput.edid.hash,
        name
    ]);
    var priority = positiveNumber(rawOutput.priority, 0);
    var enabled = rawOutput.enabled !== undefined ? toBoolean(rawOutput.enabled, true) : priority > 0;
    var modes = normalizeModes(rawOutput.modes);
    var currentModeId = firstString([
        rawOutput.currentModeId,
        rawOutput.currentMode && rawOutput.currentMode.id
    ]);
    var currentModeToken = resolveModeToken(currentModeId, rawOutput.currentMode, modes);

    if (!name && id === null) {
        return null;
    }

    return {
        id: id,
        name: name || ("output-" + String(id)),
        matchKey: matchKey || name || ("output-" + String(id)),
        enabled: enabled,
        priority: priority,
        position: parsePoint(rawOutput.pos || rawOutput.position || rawOutput.geometry),
        scale: sanitizeScale(rawOutput.scale),
        rotation: normalizeRotation(rawOutput.rotation),
        modeToken: currentModeToken,
        availableModeTokens: uniqueTokens(modes)
    };
}

function sanitizeTriggerOutput(rawOutput) {
    if (!rawOutput || typeof rawOutput !== "object") {
        return null;
    }

    var connectorName = cleanName(firstString([rawOutput.connectorName, rawOutput.name]));
    var deviceUuid = cleanName(firstString([rawOutput.deviceUuid, rawOutput.uuid]));
    var type = cleanName(firstString([rawOutput.type, rawOutput.typeLabel]));

    if (!connectorName && !deviceUuid && !type) {
        return null;
    }

    return {
        connectorName: connectorName,
        deviceUuid: deviceUuid,
        type: type
    };
}

function normalizeModes(rawModes) {
    var values = objectValues(rawModes);
    var normalized = [];

    for (var i = 0; i < values.length; i += 1) {
        var mode = values[i];
        if (!mode || typeof mode !== "object") {
            continue;
        }

        var token = modeToToken(mode);
        if (!token) {
            continue;
        }

        normalized.push({
            id: firstString([mode.id]),
            token: token
        });
    }

    return normalized;
}

function resolveModeToken(currentModeId, currentMode, modes) {
    if (currentModeId) {
        for (var i = 0; i < modes.length; i += 1) {
            if (modes[i].id === currentModeId) {
                return modes[i].token;
            }
        }
    }

    if (currentMode && typeof currentMode === "object") {
        return modeToToken(currentMode);
    }

    return null;
}

function modeToToken(mode) {
    var name = sanitizeModeToken(mode && mode.name);
    if (name) {
        return name;
    }

    if (!mode || typeof mode !== "object") {
        return null;
    }

    var size = mode.size || {
        width: mode.width,
        height: mode.height
    };
    var width = positiveNumber(size && size.width, 0);
    var height = positiveNumber(size && size.height, 0);
    var refreshRate = nullableNumber(mode.refreshRate);

    if (width <= 0 || height <= 0 || refreshRate === null) {
        return null;
    }

    return width + "x" + height + "@" + formatRefreshRate(refreshRate);
}

function sanitizeModeToken(value) {
    if (value === undefined || value === null) {
        return null;
    }

    var text = String(value).trim();
    if (/^\d+x\d+@\d+(\.\d+)?$/.test(text)) {
        return text;
    }

    return null;
}

function describeOutput(output) {
    if (!output) {
        return "Display";
    }

    return output.savedName || output.name || output.matchKey || "Display";
}

function outputAddress(output) {
    if (!output) {
        return "";
    }

    if (output.id !== null && output.id !== undefined && Number.isFinite(Number(output.id))) {
        return String(Number(output.id));
    }

    return output.name ? String(output.name) : "";
}

function shouldApplyScale(scale) {
    return Number.isFinite(scale) && scale > 0 && Math.abs(scale - 1) > 0.001;
}

function formatScale(scale) {
    return stripTrailingZeros(Number(scale).toFixed(2));
}

function formatRefreshRate(refreshRate) {
    var rounded = Math.round(refreshRate);
    if (Math.abs(refreshRate - rounded) < 0.005) {
        return String(rounded);
    }

    return stripTrailingZeros(Number(refreshRate).toFixed(2));
}

function findPrimaryOutput(outputs) {
    var primary = null;

    for (var i = 0; i < outputs.length; i += 1) {
        var output = outputs[i];
        if (!output.enabled || output.priority <= 0) {
            continue;
        }

        if (!primary || output.priority < primary.priority) {
            primary = output;
        }
    }

    return primary;
}

function takeMatch(indexMap, key, usedKeys) {
    if (!key || !indexMap[key]) {
        return null;
    }

    for (var i = 0; i < indexMap[key].length; i += 1) {
        var candidate = indexMap[key][i];
        var candidateKey = outputAddress(candidate) + "::" + candidate.matchKey;
        if (!usedKeys[candidateKey]) {
            usedKeys[candidateKey] = true;
            return candidate;
        }
    }

    return null;
}

function pushIndex(indexMap, key, value) {
    if (!key) {
        return;
    }

    if (!indexMap[key]) {
        indexMap[key] = [];
    }

    indexMap[key].push(value);
}

function cleanName(value) {
    if (value === undefined || value === null) {
        return "";
    }

    return String(value).trim();
}

function generateId(seed) {
    return "preset-" + String(seed || Date.now()).replace(/[^0-9A-Za-z]+/g, "-") + "-" + Math.floor(Math.random() * 1000000);
}

function sortPresets(presets) {
    var copy = [];
    var current = Array.isArray(presets) ? presets : [];

    for (var i = 0; i < current.length; i += 1) {
        var preset = sanitizePreset(current[i]);
        if (preset) {
            copy.push(preset);
        }
    }

    copy.sort(function(a, b) {
        var updatedCompare = String(b.updatedAt).localeCompare(String(a.updatedAt));
        if (updatedCompare !== 0) {
            return updatedCompare;
        }

        return String(a.name).localeCompare(String(b.name));
    });

    return copy;
}

function sortAutoRules(rules) {
    var copy = [];
    var current = Array.isArray(rules) ? rules : [];

    for (var i = 0; i < current.length; i += 1) {
        var rule = sanitizeAutoRule(current[i]);
        if (rule) {
            copy.push(rule);
        }
    }

    copy.sort(function(a, b) {
        if (a.enabled !== b.enabled) {
            return a.enabled ? -1 : 1;
        }

        var updatedCompare = String(b.updatedAt).localeCompare(String(a.updatedAt));
        if (updatedCompare !== 0) {
            return updatedCompare;
        }

        return describeAutoTrigger(a.trigger).localeCompare(describeAutoTrigger(b.trigger));
    });

    return copy;
}

function compareOutputsForDisplay(left, right) {
    if (left.enabled !== right.enabled) {
        return left.enabled ? -1 : 1;
    }

    if (left.priority !== right.priority) {
        return left.priority - right.priority;
    }

    return String(left.name).localeCompare(String(right.name));
}

function compareStoredOutputs(left, right) {
    if (left.enabled !== right.enabled) {
        return left.enabled ? -1 : 1;
    }

    if (left.isPrimary !== right.isPrimary) {
        return left.isPrimary ? -1 : 1;
    }

    if (left.priority !== right.priority) {
        return left.priority - right.priority;
    }

    return describeOutput(left).localeCompare(describeOutput(right));
}

function compareMatchedOutputs(left, right) {
    return compareStoredOutputs(left.preset, right.preset);
}

function compareTriggerOutputs(left, right) {
    var connectorCompare = String(left.connectorName).localeCompare(String(right.connectorName));
    if (connectorCompare !== 0) {
        return connectorCompare;
    }

    var deviceCompare = String(left.deviceUuid).localeCompare(String(right.deviceUuid));
    if (deviceCompare !== 0) {
        return deviceCompare;
    }

    return String(left.type).localeCompare(String(right.type));
}

function parsePoint(value) {
    if (!value || typeof value !== "object") {
        return null;
    }

    var x = Number(value.x);
    var y = Number(value.y);

    if (!Number.isFinite(x) || !Number.isFinite(y)) {
        return null;
    }

    return {
        x: Math.round(x),
        y: Math.round(y)
    };
}

function normalizeRotation(value) {
    if (value === undefined || value === null || value === "") {
        return "none";
    }

    if (typeof value === "string") {
        var lowered = value.toLowerCase().trim();
        if (ROTATION_TOKENS[lowered]) {
            return lowered;
        }

        var numericString = Number(lowered);
        if (Number.isFinite(numericString) && ROTATION_BY_VALUE[numericString]) {
            return ROTATION_BY_VALUE[numericString];
        }
    }

    var numeric = Number(value);
    if (Number.isFinite(numeric) && ROTATION_BY_VALUE[numeric]) {
        return ROTATION_BY_VALUE[numeric];
    }

    return "none";
}

function sanitizeScale(value) {
    var number = Number(value);
    if (!Number.isFinite(number) || number <= 0) {
        return 1;
    }

    return Number(stripTrailingZeros(number.toFixed(2)));
}

function toBoolean(value, fallback) {
    if (value === undefined || value === null) {
        return fallback;
    }

    if (typeof value === "boolean") {
        return value;
    }

    if (typeof value === "number") {
        return value !== 0;
    }

    var lowered = String(value).toLowerCase().trim();
    if (lowered === "true" || lowered === "1" || lowered === "yes") {
        return true;
    }

    if (lowered === "false" || lowered === "0" || lowered === "no") {
        return false;
    }

    return fallback;
}

function firstString(values) {
    for (var i = 0; i < values.length; i += 1) {
        if (values[i] !== undefined && values[i] !== null && values[i] !== "") {
            return String(values[i]);
        }
    }

    return "";
}

function positiveNumber(value, fallback) {
    var number = Number(value);
    if (Number.isFinite(number) && number >= 0) {
        return Math.round(number);
    }

    return fallback;
}

function nullableNumber(value) {
    var number = Number(value);
    return Number.isFinite(number) ? number : null;
}

function uniqueTokens(modes) {
    var seen = {};
    var tokens = [];

    for (var i = 0; i < modes.length; i += 1) {
        var token = modes[i].token;
        if (!token || seen[token]) {
            continue;
        }

        seen[token] = true;
        tokens.push(token);
    }

    return tokens;
}

function objectValues(value) {
    if (!value) {
        return [];
    }

    if (Array.isArray(value)) {
        return value.slice();
    }

    if (typeof value !== "object") {
        return [];
    }

    var keys = Object.keys(value);
    var values = [];

    for (var i = 0; i < keys.length; i += 1) {
        if (value[keys[i]] && typeof value[keys[i]] === "object") {
            values.push(value[keys[i]]);
        }
    }

    return values;
}

function buildConnectionSignature(outputs) {
    var normalizedOutputs = [];
    var current = Array.isArray(outputs) ? outputs : [];

    for (var i = 0; i < current.length; i += 1) {
        var output = sanitizeTriggerOutput(current[i]);
        if (output) {
            normalizedOutputs.push(output);
        }
    }

    normalizedOutputs.sort(compareTriggerOutputs);

    var rows = [];
    for (var j = 0; j < normalizedOutputs.length; j += 1) {
        rows.push([
            normalizedOutputs[j].connectorName,
            normalizedOutputs[j].deviceUuid,
            normalizedOutputs[j].type
        ]);
    }

    return JSON.stringify(rows);
}

function parseOutputOverviewHeader(line) {
    var header = String(line || "").replace(/^Output:\s*/, "");
    var tokens = header.split(/\s+/);

    return {
        id: tokens.length > 0 ? nullableNumber(tokens[0]) : null,
        connectorName: tokens.length > 1 ? String(tokens[1]) : "",
        deviceUuid: tokens.length > 2 ? tokens.slice(2).join(" ") : "",
        type: "",
        connected: false,
        enabled: false
    };
}

function isOutputTypeLine(text) {
    if (!text || text.indexOf(":") >= 0) {
        return false;
    }

    if (/^(enabled|disabled|connected|disconnected)$/i.test(text)) {
        return false;
    }

    if (/^(priority|Modes?|Custom modes|Geometry|Scale|Rotation|Overscan|Vrr|RgbRange|HDR|Wide Color Gamut|ICC profile|Color profile source|Color power preference|Brightness control|Color resolution|Allow EDR|Sharpness control|Automatic brightness|replication source|DDC\/CI)\b/i.test(text)) {
        return false;
    }

    return true;
}

function shortDeviceId(value) {
    var text = cleanName(value);
    if (text.length <= 8) {
        return text;
    }

    return text.slice(0, 8);
}

function stripAnsi(text) {
    return String(text || "").replace(/[\u001B\u009B]\[[0-9;?]*[ -/]*[@-~]/g, "");
}

function stripTrailingZeros(text) {
    return String(text).replace(/\.?0+$/, "");
}
