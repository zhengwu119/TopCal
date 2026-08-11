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
        AppearanceManager.apply()
        setupStatusItem()
        setupPopover()
        scheduleDayRefresh()
        applyLaunchAtLoginPreference()
        NotificationManager.shared.requestPermissionAndNotifyLaunch()
    }

    /// Respects the user's launch-at-login choice (defaults to on for
    /// backwards compatibility with v1.0–v1.2 behaviour). Without this the
    /// app would re-register itself after the user turns the setting off.
    private func applyLaunchAtLoginPreference() {
        let pref = UserDefaults.standard
            .object(forKey: CalendarViewController.launchAtLoginPreferenceKey) as? Bool ?? true
        let manager = LaunchAtLoginManager.shared
        if pref {
            manager.register()
        } else {
            manager.unregister()
        }
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
        calendarViewController = makeCalendarController()
        popover = NSPopover()
        popover.contentSize = AppConstants.Popover.size
        popover.behavior = .transient
        popover.contentViewController = calendarViewController
    }

    /// Creates a calendar controller wired to rebuild the popover when the
    /// user switches the language in the settings menu.
    private func makeCalendarController() -> CalendarViewController {
        let controller = CalendarViewController()
        controller.onLanguageChanged = { [weak self] in
            self?.rebuildCalendarPopover()
        }
        controller.onAppearanceChanged = { [weak self] in
            guard let self = self else { return }
            AppearanceManager.apply()
            self.statusItem.button?.image = StatusBarIconRenderer.image()
            // Rebuild so layer-based colors (which are resolved to static
            // CGColors at creation time) pick up the new appearance.
            self.rebuildCalendarPopover()
        }
        return controller
    }

    /// Rebuilds the popover content so it renders in the newly selected
    /// language (the language preference is persisted by the controller).
    private func rebuildCalendarPopover() {
        calendarViewController = makeCalendarController()
        popover.contentViewController = calendarViewController
        if popover.isShown {
            popover.contentSize = AppConstants.Popover.size
            popover.contentViewController = calendarViewController
        }
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