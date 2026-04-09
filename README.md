# Display Presets

Display Presets is a KDE Plasma 6 widget for saving monitor layouts and restoring them later with one click. It also includes a memory mode that can automatically recall a saved preset for an exact monitor and connector combination.

[简体中文](#简体中文) | [English](#english)

## 简体中文

Display Presets 是一个 KDE Plasma 6 小组件，用来保存当前显示器布局，并在之后一键恢复。它还提供“记忆模式”，可以根据完全匹配的显示器与接口组合自动恢复对应预设。

### 功能

- 保存当前显示器布局为命名预设
- 一键恢复已保存的布局
- 将特定显示器和接口组合绑定到某个预设
- 当相同连接组合再次出现时自动恢复对应预设
- 支持多种已记忆组态，例如仅内屏、内屏加 DP 外接屏、不同扩展坞或不同端口
- 内置简体中文、繁体中文和英文界面

### 依赖

- KDE Plasma 6
- `kscreen-doctor`
- `kpackagetool6`
- `msgfmt`（从源码构建翻译时需要）

推荐在 Wayland 下使用。在部分 X11 会话中，缩放恢复可能会被跳过。

### 仓库结构

- `com.aki.plasma.displaypresets/`: plasmoid 包本体
- `tests/`: QML 逻辑测试
- `scripts/`: 发布与安装辅助脚本
- `docs/`: 发布说明与手工检查清单

### 本地开发

运行测试：

```bash
qmltestrunner -input tests
```

安装或升级到当前用户：

```bash
./com.aki.plasma.displaypresets/scripts/install-local.sh
```

### 构建发布产物

```bash
./scripts/build-release.sh
```

会在 `dist/` 下生成：

- `com.aki.plasma.displaypresets-<version>.plasmoid`
  纯 plasmoid 包，适合手动 `kpackagetool6` 安装或其他打包流程。
- `com.aki.plasma.displaypresets-<version>-bundle.tar.gz`
  面向终端用户的发布包，包含 plasmoid、已编译翻译和 `install.sh`。
- `SHA256SUMS`
  校验和文件。

### 发布到 GitHub Release

如果已经安装并登录 `gh`，可直接创建或更新当前版本的 GitHub Release 草稿：

```bash
./scripts/publish-github-release.sh --rebuild
```

需要直接公开发布时，可改为：

```bash
./scripts/publish-github-release.sh --rebuild --publish
```

脚本默认会读取：

- tag: `v<Version>`
- 发布说明: `docs/github-release-v<Version>.md`
- 附件: `dist/` 下的 bundle、`.plasmoid` 和 `SHA256SUMS`

### 安装发布包

推荐最终用户下载 `-bundle.tar.gz`，因为它会一起安装翻译文件：

```bash
tar -xzf com.aki.plasma.displaypresets-<version>-bundle.tar.gz
cd com.aki.plasma.displaypresets-<version>
./install.sh
```

如果 Plasma 没有立刻刷新，小组件可通过重启 `plasmashell` 或重新登录后生效。

### 打包说明

KDE 会从标准 locale 目录加载 plasmoid 翻译。发布包或发行版包应将翻译安装到：

```text
$PREFIX/share/locale/<lang>/LC_MESSAGES/plasma_applet_com.aki.plasma.displaypresets.mo
```

plasmoid 本体应安装到：

```text
$PREFIX/share/plasma/plasmoids/com.aki.plasma.displaypresets
```

如果只安装 `.plasmoid` 包本体而不安装 locale 文件，小组件仍可工作，但翻译可能回退到英文。

### 已知限制

- 自动恢复依赖“精确匹配”的接口和设备组合。同一台显示器换到另一个端口，会被视为另一种组态。
- 某些 X11 会话下，缩放恢复可能会被跳过。
- 单独的 `.plasmoid` 文件不会自动把翻译装进系统 locale 路径。

### 发布前检查

首次公开发布前，请先检查 [docs/release-checklist.md](docs/release-checklist.md)。

## English

Display Presets is a KDE Plasma 6 widget for saving monitor layouts and restoring them later with one click. It also includes a memory mode that can automatically recall a saved preset for an exact monitor and connector combination.

### Features

- Save the current display layout as a named preset
- Restore a saved layout with one click
- Bind exact monitor and connector combinations to a preset
- Automatically recall a preset when the same setup is connected again
- Works with multiple remembered setups, such as internal-only, internal plus DP monitor, or different docks and ports
- Built-in Simplified Chinese, Traditional Chinese, and English support

### Requirements

- KDE Plasma 6
- `kscreen-doctor`
- `kpackagetool6`
- `msgfmt` for building translations from source

Wayland is recommended. On some X11 sessions, display scale restoration may be skipped.

### Repository Layout

- `com.aki.plasma.displaypresets/`: plasmoid package
- `tests/`: QML logic tests
- `scripts/`: release and bundle install helpers
- `docs/`: release notes and manual checklist

### Local Development

Run tests:

```bash
qmltestrunner -input tests
```

Install or upgrade for the current user:

```bash
./com.aki.plasma.displaypresets/scripts/install-local.sh
```

### Building Release Artifacts

```bash
./scripts/build-release.sh
```

This creates:

- `com.aki.plasma.displaypresets-<version>.plasmoid`
  Plain plasmoid archive for manual `kpackagetool6` installation or downstream packaging.
- `com.aki.plasma.displaypresets-<version>-bundle.tar.gz`
  End-user bundle with the plasmoid, compiled translations, and `install.sh`.
- `SHA256SUMS`
  Checksums for the release files.

### Publishing to GitHub Releases

If `gh` is installed and authenticated, create or update a draft GitHub release for the current version with:

```bash
./scripts/publish-github-release.sh --rebuild
```

To publish immediately instead of creating a draft:

```bash
./scripts/publish-github-release.sh --rebuild --publish
```

By default, the script uses:

- tag: `v<Version>`
- notes: `docs/github-release-v<Version>.md`
- assets: the bundle archive, `.plasmoid`, and `SHA256SUMS` from `dist/`

### Installing a Release Bundle

For end users, the `-bundle.tar.gz` archive is the recommended download because it installs translations alongside the plasmoid:

```bash
tar -xzf com.aki.plasma.displaypresets-<version>-bundle.tar.gz
cd com.aki.plasma.displaypresets-<version>
./install.sh
```

If Plasma does not refresh immediately, restart `plasmashell` or log out and back in.

### Packaging Notes

KDE loads plasmoid translations from standard locale directories. Packaged installs should place translations at:

```text
$PREFIX/share/locale/<lang>/LC_MESSAGES/plasma_applet_com.aki.plasma.displaypresets.mo
```

The plasmoid package itself should be installed at:

```text
$PREFIX/share/plasma/plasmoids/com.aki.plasma.displaypresets
```

If only the plain `.plasmoid` package is installed without locale files, the widget will still work, but translated UI strings may fall back to English.

### Known Limitations

- Automatic recall matches exact connector and device combinations. The same monitor on a different port is treated as a different setup.
- On some X11 sessions, scale restoration may be skipped.
- A plain `.plasmoid` archive does not automatically install translations into the system locale path.

### Release Checklist

Before publishing for the first time, review [docs/release-checklist.md](docs/release-checklist.md).
