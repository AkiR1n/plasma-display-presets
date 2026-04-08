.pragma library

function quote(value) {
    if (value === undefined || value === null) {
        return "''";
    }

    var text = String(value);
    if (text.length === 0) {
        return "''";
    }

    return "'" + text.replace(/'/g, "'\"'\"'") + "'";
}

function joinCommand(argv) {
    var args = Array.isArray(argv) ? argv : [];
    return args.map(quote).join(" ");
}
