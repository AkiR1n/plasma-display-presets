# Display Presets

[![Release](https://img.shields.io/github/v/release/AkiR1n/plasma-display-presets?display_name=tag)](https://github.com/AkiR1n/plasma-display-presets/releases)
[![CI](https://github.com/AkiR1n/plasma-display-presets/actions/workflows/ci.yml/badge.svg)](https://github.com/AkiR1n/plasma-display-presets/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/AkiR1n/plasma-display-presets)](LICENSE)

[English](README.md)

Display Presets 是一个 KDE Plasma 6 小组件，用来保存显示器布局，并在之后一键恢复。它的记忆模式可以在再次检测到同一组显示器和接口组合时，自动恢复对应预设。

## 功能特性

- 将当前显示器布局保存为命名预设
- 直接在小组件内恢复已保存布局
- 将预设绑定到精确的显示器和接口签名
- 为仅内屏、桌面外接屏、扩展坞和特定端口分别记忆不同组态
- 在界面中直接重命名、覆盖、删除和重新绑定预设
- 内置英文、简体中文和繁体中文界面

## 安装方法

请从 [Releases](https://github.com/AkiR1n/plasma-display-presets/releases) 页面下载最新的 `-bundle.tar.gz` 安装包。推荐使用 bundle 版本，因为它会同时安装小组件和翻译文件。

```bash
tar -xzf com.aki.plasma.displaypresets-<version>-bundle.tar.gz
cd com.aki.plasma.displaypresets-<version>
./install.sh
```

安装完成后，在 Plasma 的小组件选择器中添加 **Display Presets**。如果界面没有立刻刷新，可重启 `plasmashell` 或重新登录。

## 依赖要求

- KDE Plasma 6
- `kscreen-doctor`
- `kpackagetool6`
- 推荐使用 Wayland

## 记忆模式

记忆模式面向反复出现的显示器组态。它会匹配当前连接的显示器集合，以及每台显示器所使用的接口路径，然后恢复你之前绑定到这一组签名的预设。这样就可以分别记住仅内屏、固定 DP 口外接屏、不同扩展坞或不同转接链路下的布局。

## 已知限制

- 匹配是精确的。同一台显示器换到另一个端口，会被视为另一种组态。
- 在部分 X11 会话中，缩放恢复可能会被跳过。
- 纯 `.plasmoid` 包不会把翻译安装到标准 locale 路径，终端用户应优先使用 bundle 发布包。

## 项目链接

- [发布页](https://github.com/AkiR1n/plasma-display-presets/releases)
- [更新日志](CHANGELOG.md)
- [英文 README](README.md)
- [贡献说明](CONTRIBUTING.md)
- [许可证](LICENSE)
