# MenuBarCalendar v3

极简 macOS 顶部菜单栏日历。

## 功能

- 顶部菜单栏显示今天是几号
- 点击日期弹出当月日历，当天高亮
- 开机自启（LaunchAgent）
- 启动通知 + 终端调试日志

## 覆盖安装前必做

```bash
# 杀掉所有旧实例
pkill -f MenuBarCalendar
# 确认不再运行
ps aux | grep -i MenuBarCalendar | grep -v grep
```

## 安装与使用

1. 解压 zip，将 `MenuBarCalendar.app` 拖入 **应用程序** 覆盖旧版
2. 打开"终端"，运行（观察调试日志）：

   ```bash
   /Applications/MenuBarCalendar.app/Contents/MacOS/MenuBarCalendar
   ```

   预期输出类似：

   ```
   [MenuBarCalendar] Starting up...
   [MenuBarCalendar] macOS Version 26.0 ...
   [MenuBarCalendar] StatusItem created, length=32.0, button=OK
   [MenuBarCalendar] Button configured, now setting image...
   [MenuBarCalendar] Updated to day: 25
   [MenuBarCalendar] LaunchAgent registered.
   [MenuBarCalendar] Ready — should see date in menu bar.
   ```

3. 观察：
   - 终端有日志 = 应用正常运行
   - 收到"日历已就绪"通知 = 通知权限 OK
   - 菜单栏出现日期数字 = 一切正常
4. 如果日志正常但菜单栏仍无图标：这可能意味着该 macOS 版本隐藏了新增的菜单栏项目。点击菜单栏右侧的控制中心（或打开任意全屏应用）看看是否可以拖出。

## 卸载

```bash
launchctl unload ~/Library/LaunchAgents/com.workbuddy.menubarcalendar.plist
rm ~/Library/LaunchAgents/com.workbuddy.menubarcalendar.plist
# 然后删除 MenuBarCalendar.app
```

## 重新编译

```bash
cd MenuBarCalendar
swiftc -o MenuBarCalendar.app/Contents/MacOS/MenuBarCalendar \
  -framework AppKit -framework Foundation -framework UserNotifications \
  AppDelegate.swift CalendarViewController.swift LaunchAtLoginManager.swift
codesign --force --deep --sign - MenuBarCalendar.app
```
