# Release Checklist

## Still Manual

- Add screenshots or a short demo GIF before publishing the repository or release page.
- Add the final public repository URL back into `metadata.json` once the repository location is fixed.
- Create a signed tag such as `v1.0.0`.
- Write release notes for GitHub or your chosen release page.

## Before Publishing

- Run `qmltestrunner -input tests`.
- Run `./scripts/build-release.sh`.
- Test `./install.sh` from the generated bundle archive in a clean user environment.
- Verify the plasmoid can be added from the widget picker after installation.
- Verify save, restore, delete, rename, and memory mode behavior on your real monitor setups.

## Distribution Notes

- For GitHub releases, publish the `-bundle.tar.gz` archive for end users.
- For KDE Store or distro packages, make sure the compiled `.mo` files are installed to the standard locale path, not only shipped inside the plasmoid package.
