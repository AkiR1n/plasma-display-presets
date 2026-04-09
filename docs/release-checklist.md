# Release Checklist

## Still Manual

- Add screenshots or a short demo GIF before publishing the repository or release page.
- Review and adjust [docs/github-release-v1.0.0.md](github-release-v1.0.0.md) before publishing the first release.
- If you do not use `gh`, create the GitHub Release manually and upload the generated artifacts from `dist/`.

## Before Publishing

- Run `qmltestrunner -input tests`.
- Run `./scripts/build-release.sh`.
- If using GitHub CLI, run `./scripts/publish-github-release.sh --rebuild` to create or update a draft release.
- Test `./install.sh` from the generated bundle archive in a clean user environment.
- Verify the plasmoid can be added from the widget picker after installation.
- Verify save, restore, delete, rename, and memory mode behavior on your real monitor setups.

## Distribution Notes

- For GitHub releases, publish the `-bundle.tar.gz` archive for end users.
- For KDE Store or distro packages, make sure the compiled `.mo` files are installed to the standard locale path, not only shipped inside the plasmoid package.
