#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE_DIR="${ROOT_DIR}/com.aki.plasma.displaypresets"
METADATA_FILE="${PACKAGE_DIR}/metadata.json"
DIST_DIR="${ROOT_DIR}/dist"
PACKAGE_ID=$(basename "${PACKAGE_DIR}")
VERSION=$(sed -n 's/.*"Version": "\(.*\)".*/\1/p' "${METADATA_FILE}" | head -n 1)
TAG="v${VERSION}"
TITLE="Display Presets ${TAG}"
NOTES_FILE="${ROOT_DIR}/docs/github-release-${TAG}.md"
DRAFT=1
REBUILD=0

usage() {
    cat <<'EOF'
Usage: ./scripts/publish-github-release.sh [options]

Create or update a GitHub release for the current version.

Options:
  --publish           Create or update a published release instead of a draft
  --rebuild           Rebuild release artifacts before publishing
  --notes-file PATH   Use a custom release notes file
  --title TEXT        Override the GitHub release title
  -h, --help          Show this help message

By default, this script expects:
  - tag: v<Version> from com.aki.plasma.displaypresets/metadata.json
  - notes: docs/github-release-v<Version>.md
  - artifacts in dist/
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --publish)
            DRAFT=0
            shift
            ;;
        --rebuild)
            REBUILD=1
            shift
            ;;
        --notes-file)
            if [ $# -lt 2 ]; then
                printf 'Missing value for %s\n' "$1" >&2
                exit 1
            fi
            NOTES_FILE="$2"
            shift 2
            ;;
        --title)
            if [ $# -lt 2 ]; then
                printf 'Missing value for %s\n' "$1" >&2
                exit 1
            fi
            TITLE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "${VERSION}" ]; then
    printf 'Could not determine package version from %s\n' "${METADATA_FILE}" >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    printf 'GitHub CLI (gh) is not installed.\n' >&2
    printf 'Install gh first, then rerun this script.\n' >&2
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    printf 'GitHub CLI is not authenticated.\n' >&2
    printf 'Run: gh auth login\n' >&2
    exit 1
fi

if ! git -C "${ROOT_DIR}" rev-parse --verify --quiet "${TAG}" >/dev/null; then
    printf 'Tag %s does not exist locally.\n' "${TAG}" >&2
    exit 1
fi

if [ "${REBUILD}" -eq 1 ]; then
    "${ROOT_DIR}/scripts/build-release.sh"
fi

PLASMOID_ARCHIVE="${DIST_DIR}/${PACKAGE_ID}-${VERSION}.plasmoid"
BUNDLE_ARCHIVE="${DIST_DIR}/${PACKAGE_ID}-${VERSION}-bundle.tar.gz"
CHECKSUM_FILE="${DIST_DIR}/SHA256SUMS"

for file in "${PLASMOID_ARCHIVE}" "${BUNDLE_ARCHIVE}" "${CHECKSUM_FILE}"; do
    if [ ! -f "${file}" ]; then
        printf 'Missing release artifact: %s\n' "${file}" >&2
        printf 'Run ./scripts/build-release.sh or pass --rebuild.\n' >&2
        exit 1
    fi
done

if [ ! -f "${NOTES_FILE}" ]; then
    printf 'Release notes file not found: %s\n' "${NOTES_FILE}" >&2
    exit 1
fi

EDIT_ARGS=()
CREATE_ARGS=()
if [ "${DRAFT}" -eq 1 ]; then
    EDIT_ARGS+=(--draft)
    CREATE_ARGS+=(--draft)
else
    EDIT_ARGS+=(--draft=false)
fi

if gh release view "${TAG}" >/dev/null 2>&1; then
    gh release edit "${TAG}" \
        --title "${TITLE}" \
        --notes-file "${NOTES_FILE}" \
        "${EDIT_ARGS[@]}"
    gh release upload "${TAG}" \
        "${BUNDLE_ARCHIVE}" \
        "${PLASMOID_ARCHIVE}" \
        "${CHECKSUM_FILE}" \
        --clobber
    printf 'Updated GitHub release %s\n' "${TAG}"
else
    gh release create "${TAG}" \
        "${BUNDLE_ARCHIVE}" \
        "${PLASMOID_ARCHIVE}" \
        "${CHECKSUM_FILE}" \
        --title "${TITLE}" \
        --notes-file "${NOTES_FILE}" \
        "${CREATE_ARGS[@]}" \
        --verify-tag
    printf 'Created GitHub release %s\n' "${TAG}"
fi
