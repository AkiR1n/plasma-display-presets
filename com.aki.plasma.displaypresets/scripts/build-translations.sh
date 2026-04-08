#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)
PO_DIR="${PROJECT_DIR}/po"
DOMAIN="plasma_applet_com.aki.plasma.displaypresets"
OUTPUT_ROOT="${1:-${PROJECT_DIR}/build/locale}"

mkdir -p "${OUTPUT_ROOT}"

for po_file in "${PO_DIR}"/*.po; do
    language=$(basename "${po_file}" .po)
    target_dir="${OUTPUT_ROOT}/${language}/LC_MESSAGES"
    target_file="${target_dir}/${DOMAIN}.mo"

    mkdir -p "${target_dir}"
    msgfmt --check --output-file="${target_file}" "${po_file}"
    printf 'Built %s\n' "${target_file}"
done
