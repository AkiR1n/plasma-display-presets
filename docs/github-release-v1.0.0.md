# Display Presets v1.0.0

## English

Initial public release of Display Presets for KDE Plasma 6.

### Highlights

- Save the current display layout as a named preset
- Restore a saved layout with one click
- Use memory mode to automatically recall a preset for an exact monitor and connector combination
- Manage multiple remembered setups, such as internal-only, desk monitor on a specific DP port, or different docks
- Rename, overwrite, delete, and rebind presets directly from the widget
- Built-in Simplified Chinese, Traditional Chinese, and English support

### Downloads

- `com.aki.plasma.displaypresets-1.0.0-bundle.tar.gz`
  Recommended for end users. Includes the plasmoid, compiled translations, and an installer script.
- `com.aki.plasma.displaypresets-1.0.0.plasmoid`
  Plain plasmoid archive for manual or downstream packaging workflows.

### Installation

```bash
tar -xzf com.aki.plasma.displaypresets-1.0.0-bundle.tar.gz
cd com.aki.plasma.displaypresets-1.0.0
./install.sh
```

If Plasma does not refresh immediately, restart `plasmashell` or log out and back in.

### Notes

- Plasma 6 is required.
- `kscreen-doctor` is required.
- Wayland is recommended.
- Automatic recall matches exact monitor and connector combinations.

## 简体中文

Display Presets for KDE Plasma 6 的首次公开发布版本。

### 主要特性

- 将当前显示器布局保存为命名预设
- 一键恢复已保存布局
- 通过记忆模式，根据精确匹配的显示器和接口组合自动恢复对应预设
- 支持多种已记忆组态，例如仅内屏、固定 DP 口外接屏、不同扩展坞等
- 可直接在小组件内重命名、覆盖、删除和重新绑定预设
- 内置简体中文、繁体中文和英文界面

### 下载说明

- `com.aki.plasma.displaypresets-1.0.0-bundle.tar.gz`
  推荐终端用户使用，包含 plasmoid、本地化翻译和安装脚本。
- `com.aki.plasma.displaypresets-1.0.0.plasmoid`
  纯 plasmoid 包，适合手动安装或下游打包流程。

### 安装方法

```bash
tar -xzf com.aki.plasma.displaypresets-1.0.0-bundle.tar.gz
cd com.aki.plasma.displaypresets-1.0.0
./install.sh
```

如果 Plasma 没有立即刷新，可重启 `plasmashell` 或重新登录。

### 说明

- 需要 Plasma 6
- 需要 `kscreen-doctor`
- 推荐在 Wayland 下使用
- 自动恢复依赖精确匹配的显示器和接口组合
