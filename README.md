# Display Presets

[![Release](https://img.shields.io/github/v/release/AkiR1n/plasma-display-presets?display_name=tag)](https://github.com/AkiR1n/plasma-display-presets/releases)
[![CI](https://github.com/AkiR1n/plasma-display-presets/actions/workflows/ci.yml/badge.svg)](https://github.com/AkiR1n/plasma-display-presets/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/AkiR1n/plasma-display-presets)](LICENSE)

[简体中文](README.zh-CN.md)

Display Presets is a KDE Plasma 6 widget for saving monitor layouts and restoring them later with one click. Its memory mode can automatically re-apply a preset when the same monitor and connector combination is detected again.

## Features

- Save the current display layout as a named preset
- Restore saved layouts directly from the widget
- Bind a preset to an exact monitor and connector signature
- Automatically recall different setups for laptop-only mode, desk monitors, docks, and specific ports
- Rename, overwrite, delete, and rebind presets from the UI
- Built-in English, Simplified Chinese, and Traditional Chinese support

## Installation

Download the latest `-bundle.tar.gz` package from the [Releases](https://github.com/AkiR1n/plasma-display-presets/releases) page. The bundle is the recommended install target because it includes translations alongside the widget.

```bash
tar -xzf com.aki.plasma.displaypresets-<version>-bundle.tar.gz
cd com.aki.plasma.displaypresets-<version>
./install.sh
```

After installation, add **Display Presets** from the Plasma widget picker. If Plasma does not refresh immediately, restart `plasmashell` or log out and back in.

## Requirements

- KDE Plasma 6
- `kscreen-doctor`
- `kpackagetool6`
- Wayland recommended

## Memory Mode

Memory mode is designed for recurring display setups. It matches the exact connected monitor set and the connector used for each display, then restores the preset you previously bound to that signature. This allows separate remembered layouts for internal-only mode, a monitor on a specific DP port, different docks, or different adapter chains.

## Limitations

- Matching is exact. The same monitor on a different port is treated as a different setup.
- On some X11 sessions, display scale restoration may be skipped.
- The plain `.plasmoid` archive does not install translations into the standard locale path. End users should prefer the bundle release.

## Project Links

- [Releases](https://github.com/AkiR1n/plasma-display-presets/releases)
- [Changelog](CHANGELOG.md)
- [Chinese README](README.zh-CN.md)
- [Contributing](CONTRIBUTING.md)
- [License](LICENSE)
