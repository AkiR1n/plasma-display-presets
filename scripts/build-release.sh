#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE_DIR="${ROOT_DIR}/com.aki.plasma.displaypresets"
PACKAGE_ID=$(basename "${PACKAGE_DIR}")
METADATA_FILE="${PACKAGE_DIR}/metadata.json"
DIST_DIR="${ROOT_DIR}/dist"
VERSION=$(sed -n 's/.*"Version": "\(.*\)".*/\1/p' "${METADATA_FILE}" | head -n 1)

if [ -z "${VERSION}" ]; then
    printf 'Could not determine package version from %s\n' "${METADATA_FILE}" >&2
    exit 1
fi

PLASMOID_ARCHIVE="${DIST_DIR}/${PACKAGE_ID}-${VERSION}.plasmoid"
BUNDLE_NAME="${PACKAGE_ID}-${VERSION}"
BUNDLE_DIR="${DIST_DIR}/${BUNDLE_NAME}"
BUNDLE_PACKAGE_DIR="${BUNDLE_DIR}/${PACKAGE_ID}"
BUNDLE_ARCHIVE="${DIST_DIR}/${BUNDLE_NAME}-bundle.tar.gz"
CHECKSUM_FILE="${DIST_DIR}/SHA256SUMS"

rm -rf "${BUNDLE_DIR}" "${PLASMOID_ARCHIVE}" "${BUNDLE_ARCHIVE}" "${CHECKSUM_FILE}"
mkdir -p "${BUNDLE_PACKAGE_DIR}"

cp -a "${PACKAGE_DIR}/contents" "${BUNDLE_PACKAGE_DIR}/"
install -Dm0644 "${PACKAGE_DIR}/metadata.json" "${BUNDLE_PACKAGE_DIR}/metadata.json"
"${PACKAGE_DIR}/scripts/build-translations.sh" "${BUNDLE_DIR}/share/locale"
install -Dm0755 "${ROOT_DIR}/scripts/install-bundle.sh" "${BUNDLE_DIR}/install.sh"
install -Dm0644 "${ROOT_DIR}/README.md" "${BUNDLE_DIR}/README.md"
install -Dm0644 "${ROOT_DIR}/CHANGELOG.md" "${BUNDLE_DIR}/CHANGELOG.md"
install -Dm0644 "${ROOT_DIR}/LICENSE" "${BUNDLE_DIR}/LICENSE"

bsdtar --format=zip -cf "${PLASMOID_ARCHIVE}" -C "${BUNDLE_DIR}" "${PACKAGE_ID}"
bsdtar -czf "${BUNDLE_ARCHIVE}" -C "${DIST_DIR}" "${BUNDLE_NAME}"

(
    cd "${DIST_DIR}"
    sha256sum "$(basename "${PLASMOID_ARCHIVE}")" "$(basename "${BUNDLE_ARCHIVE}")" > "${CHECKSUM_FILE}"
)

printf 'Built %s\n' "${PLASMOID_ARCHIVE}"
printf 'Built %s\n' "${BUNDLE_ARCHIVE}"
printf 'Wrote %s\n' "${CHECKSUM_FILE}"
