#!/usr/bin/env bash
set -euo pipefail

PACKAGE_ID="com.aki.plasma.displaypresets"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)
TARGET_ROOT="${XDG_DATA_HOME:-${HOME}/.local/share}"
TARGET_PACKAGE_DIR="${TARGET_ROOT}/plasma/plasmoids/${PACKAGE_ID}"

run_kpackagetool() {
    local mode=$1
    local package_dir=$2
    local output

    if ! output=$(kpackagetool6 --type Plasma/Applet "--${mode}" "${package_dir}" 2>&1); then
        printf '%s\n' "${output}" >&2
        return 1
    fi

    printf '%s\n' "${output}" | sed '/^Error: Plugin .* is not installed\.$/d'
}

"${SCRIPT_DIR}/build-translations.sh" "${TARGET_ROOT}/locale"

if [ -d "${TARGET_PACKAGE_DIR}" ]; then
    run_kpackagetool upgrade "${PROJECT_DIR}"
else
    run_kpackagetool install "${PROJECT_DIR}"
fi
