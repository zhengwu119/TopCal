import AppKit
import Foundation
import os.log

private let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? AppConstants.fallbackBundleIdentifier,
                        category: "app")

/// Thin app delegate — owns the status bar item, the popover, and the day-refresh timer.
/// Heavy work (icon rendering, notifications, launch-at-login) lives in dedicated
/// types under Sources/{Support,Notifications,LaunchAtLogin}.
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var calendarViewController: CalendarViewController!
    private var refreshTimer: Timer?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        scheduleDayRefresh()
        LaunchAtLoginManager.shared.register()
        NotificationManager.shared.requestPermissionAndNotifyLaunch()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else {
            os_log("Failed to create status bar button", log: log, type: .error)
            return
        }
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.appearsDisabled = false
        button.image = StatusBarIconRenderer.image()
    }

    private func setupPopover() {
        calendarViewController = CalendarViewController()
        popover = NSPopover()
        popover.contentSize = AppConstants.Popover.size
        popover.behavior = .transient
        popover.contentViewController = calendarViewController
    }

    private func scheduleDayRefresh() {
        // Re-render the menu bar icon every minute so the day updates at midnight.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.statusItem.button?.image = StatusBarIconRenderer.image()
        }
    }

    // MARK: - Popover

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        calendarViewController.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}