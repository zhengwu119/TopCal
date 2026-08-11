# MenuBarCalendar

一个极简的 macOS 顶部菜单栏日历小工具：菜单栏显示今天的日期，点击弹出当月日历，支持月份/年份切换。

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## 功能

- 📅 顶部菜单栏显示今天的日期（如 `25`）
- 🗓 点击弹出当月日历，当天高亮
- ◀ ▶ 弹窗内支持月份切换
- 🚀 开机自启（通过 LaunchAgent，无需辅助应用）
- 🔔 启动通知（可选，需授予通知权限）
- ⚡ 原生 AppKit 实现，无第三方依赖

## 系统要求

- macOS 13.0 及以上（arm64 / x86_64）
- 从源码构建需要 Xcode Command Line Tools（`xcode-select --install`）

## 安装

从 [Releases](../../releases) 下载最新的 `.app`，拖入 **应用程序** 文件夹后运行。

> 首次启动时应用会注册开机自启项，并可能请求通知权限——两者都可拒绝。

## 从源码构建

```bash
git clone <你的仓库地址> MenuBarCalendar
cd MenuBarCalendar
./build.sh
open build/MenuBarCalendar.app
```

或手动编译：

```bash
swiftc -o MenuBarCalendar.app/Contents/MacOS/MenuBarCalendar \
  -framework AppKit -framework Foundation -framework UserNotifications \
  main.swift AppDelegate.swift CalendarViewController.swift LaunchAtLoginManager.swift
cp Info.plist MenuBarCalendar.app/Contents/Info.plist
codesign --force --deep --sign - MenuBarCalendar.app
```

## 使用

- 菜单栏显示今天日期，点击切换日历弹窗
- 弹窗内点击 `◀` / `▶` 切换月份
- 点击弹窗外任意位置关闭

## 卸载

```bash
# 1. 移除开机自启
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.menubarcalendar.app.plist
rm ~/Library/LaunchAgents/com.menubarcalendar.app.plist

# 2. 退出并删除应用
pkill MenuBarCalendar
rm -rf /Applications/MenuBarCalendar.app
```

## 实现原理

- **菜单栏图标**：将日期数字绘制成 `NSImage` 设置到 `NSStatusBarButton`——比 `button.title` 在新版 macOS 上更可靠
- **弹窗**：`NSPopover` + `.transient` 行为（点击外部自动关闭）
- **开机自启**：向 `~/Library/LaunchAgents` 写入 LaunchAgent plist，用 `launchctl bootstrap` 加载——支持 ad-hoc 签名，无需开发者账号或辅助应用
- **入口**：`main.swift` 使用显式顶层代码而非 `@main`，因为 macOS 26 / Swift 6.2 上 `@main` 在 `NSApplicationDelegate` 子类上会静默失败（详见 `main.swift` 注释）

## 项目结构

```
├── main.swift                    # 显式应用入口
├── AppDelegate.swift             # 菜单栏图标、弹窗、通知
├── CalendarViewController.swift  # 日历网格 UI + 月份切换
├── LaunchAtLoginManager.swift    # 开机自启的安装/移除
├── Info.plist                    # 应用配置（LSUIElement = 菜单栏应用）
├── build.sh                      # 一键构建脚本
└── .github/workflows/build.yml   # CI：编译并校验签名
```

## 参与贡献

欢迎提交 Issue 和 PR！请确保：

1. 代码能通过 `./build.sh` 编译
2. 发布代码中不要新增 `print()` 调试输出——如需日志请使用 `os_log`
3. 改动聚焦且附说明

## 开源协议

[MIT](LICENSE) © Alex Liu
