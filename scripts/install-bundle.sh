#!/usr/bin/env bash
set -euo pipefail

PACKAGE_ID="com.aki.plasma.displaypresets"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [ -d "${SCRIPT_DIR}/${PACKAGE_ID}" ]; then
    BUNDLE_ROOT="${SCRIPT_DIR}"
elif [ -d "${SCRIPT_DIR}/../${PACKAGE_ID}" ]; then
    BUNDLE_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)
else
    printf 'Could not find %s next to the installer.\n' "${PACKAGE_ID}" >&2
    exit 1
fi

PACKAGE_DIR="${BUNDLE_ROOT}/${PACKAGE_ID}"
SOURCE_LOCALE_DIR="${BUNDLE_ROOT}/share/locale"
TARGET_ROOT="${XDG_DATA_HOME:-${HOME}/.local/share}"
TARGET_LOCALE_DIR="${TARGET_ROOT}/locale"
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

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    printf 'kpackagetool6 is required to install this plasmoid.\n' >&2
    exit 1
fi

if [ -d "${SOURCE_LOCALE_DIR}" ]; then
    while IFS= read -r -d '' file; do
        relative_path=${file#"${SOURCE_LOCALE_DIR}/"}
        install -Dm0644 "${file}" "${TARGET_LOCALE_DIR}/${relative_path}"
    done < <(find "${SOURCE_LOCALE_DIR}" -type f -name '*.mo' -print0)
fi

if [ -d "${TARGET_PACKAGE_DIR}" ]; then
    run_kpackagetool upgrade "${PACKAGE_DIR}"
else
    run_kpackagetool install "${PACKAGE_DIR}"
fi

printf 'Installed %s to %s\n' "${PACKAGE_ID}" "${TARGET_ROOT}"
printf 'Restart plasmashell or log out and back in if the widget does not refresh immediately.\n'
