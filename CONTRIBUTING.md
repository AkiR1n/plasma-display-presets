# Contributing

Thanks for contributing to Display Presets.

## Requirements

- KDE Plasma 6
- `kscreen-doctor`
- `kpackagetool6`
- `msgfmt`
- `qmltestrunner`

## Test

Run QML tests in headless mode:

```bash
env QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qmltestrunner -input tests
```

## Local Install

Install or upgrade the plasmoid for the current user:

```bash
./com.aki.plasma.displaypresets/scripts/install-local.sh
```

## Release Artifacts

Build release packages and checksums:

```bash
./scripts/build-release.sh
```

This writes the end-user bundle, plain `.plasmoid` package, and `SHA256SUMS` into `dist/`.

## GitHub Release Helper

If `gh` is installed and authenticated, create or update the GitHub release for the current version:

```bash
./scripts/publish-github-release.sh --rebuild
```
