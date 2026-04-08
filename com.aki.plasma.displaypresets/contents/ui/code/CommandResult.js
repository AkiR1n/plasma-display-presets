.pragma library

function fromData(data) {
    var payload = data || {};

    return {
        stdout: firstString([
            payload.stdout,
            payload.output,
            payload.standardOutput,
            payload.standardoutput
        ]),
        stderr: firstString([
            payload.stderr,
            payload.error,
            payload.standardError,
            payload.standarderror
        ]),
        exitCode: firstNumber([
            payload["exit code"],
            payload.exitCode,
            payload.exitcode
        ], -1),
        exitStatus: firstNumber([
            payload["exit status"],
            payload.exitStatus,
            payload.exitstatus
        ], 0)
    };
}

function firstString(values) {
    for (var i = 0; i < values.length; i += 1) {
        var value = values[i];
        if (value === undefined || value === null) {
            continue;
        }

        return String(value);
    }

    return "";
}

function firstNumber(values, fallback) {
    for (var i = 0; i < values.length; i += 1) {
        var value = values[i];
        if (value === undefined || value === null || value === "") {
            continue;
        }

        var number = Number(value);
        if (Number.isFinite(number)) {
            return number;
        }
    }

    return fallback;
}
