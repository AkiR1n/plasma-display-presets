# Display Presets Plasmoid

Plasma 6 widget for saving the current monitor layout and restoring it later with one click.

## Layout

- `com.aki.plasma.displaypresets/`: plasmoid package
- `tests/`: QML logic tests

## Local checks

```bash
qmltestrunner -input /home/aki/garage/tests
```

## Install for manual testing

```bash
kpackagetool6 --type Plasma/Applet --install /home/aki/garage/com.aki.plasma.displaypresets
```
