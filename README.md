# Display Presets

Display Presets is a Plasma 6 widget for saving monitor layouts and restoring them later with one click. It also includes a memory mode that can automatically recall a saved preset for an exact monitor and connector combination.

## Features

- Save the current display layout as a named preset.
- Restore a saved layout with one click.
- Bind exact monitor and connector combinations to presets.
- Automatically recall a preset when the same setup is connected again.
- Works with multiple remembered setups, such as internal-only, internal plus DP monitor, or different docks and ports.
- Built-in Simplified Chinese, Traditional Chinese, and English support.

## Requirements

- KDE Plasma 6
- `kscreen-doctor`
- `kpackagetool6`
- `msgfmt` for building translations from source

Wayland is recommended. On X11, display scale restoration may be skipped depending on session support.

## Repository Layout

- `com.aki.plasma.displaypresets/`: plasmoid package
- `tests/`: QML logic tests
- `scripts/`: release and bundle install helpers
- `docs/`: release notes and manual checklist

## Local Development

Run the logic tests:

```bash
qmltestrunner -input tests
```

Install or upgrade the plasmoid for the current user from this repository:

```bash
./com.aki.plasma.displaypresets/scripts/install-local.sh
```

## Building Release Artifacts

Build release archives from the current checkout:

```bash
./scripts/build-release.sh
```

This creates files under `dist/`:

- `com.aki.plasma.displaypresets-<version>.plasmoid`
  Plain plasmoid package archive. Useful for packaging workflows and manual `kpackagetool6` installs.
- `com.aki.plasma.displaypresets-<version>-bundle.tar.gz`
  End-user bundle that includes the plasmoid, compiled translations, and an `install.sh` helper.
- `SHA256SUMS`
  Checksums for the generated archives.

## Installing a Release Bundle

For end users, the bundle archive is the recommended download because it installs translations alongside the plasmoid:

```bash
tar -xzf com.aki.plasma.displaypresets-<version>-bundle.tar.gz
cd com.aki.plasma.displaypresets-<version>
./install.sh
```

If Plasma does not refresh the widget immediately, restart `plasmashell` or log out and back in.

## Packaging Notes

KDE loads plasmoid translations from standard locale directories. For packaged installs, the compiled translation files should be installed to:

```text
$PREFIX/share/locale/<lang>/LC_MESSAGES/plasma_applet_com.aki.plasma.displaypresets.mo
```

The plasmoid package itself should be installed to:

```text
$PREFIX/share/plasma/plasmoids/com.aki.plasma.displaypresets
```

If you only install the plain plasmoid archive without the locale files, the widget will still work, but translated UI strings may fall back to English.

## Known Limitations

- Automatic recall matches exact connector and device combinations. The same monitor on a different port is treated as a different setup.
- On some X11 sessions, scale restoration may be skipped.
- A plain plasmoid package archive does not, by itself, install compiled translations into the system locale path.

## Release Checklist

Before the first public release, go through [docs/release-checklist.md](docs/release-checklist.md).
