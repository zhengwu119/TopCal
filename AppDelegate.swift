import AppKit
import Foundation
import os.log
import UserNotifications

private let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.topcal.app",
                        category: "app")

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var calendarViewController: CalendarViewController!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else {
            os_log("Failed to create status bar button", log: log, type: .error)
            return
        }

        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.appearsDisabled = false

        updateDateDisplay()

        // Calendar popover
        calendarViewController = CalendarViewController()
        popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height: 270)
        popover.behavior = .transient
        popover.contentViewController = calendarViewController

        // Refresh the day number at midnight
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateDateDisplay()
        }

        // Launch at login
        LaunchAtLoginManager.shared.register()

        // Confirm the app is running with a notification (optional, permission-gated)
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted { self.showLaunchNotification() }
            }
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    private func showPopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        calendarViewController.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }

    private func updateDateDisplay() {
        let day = Calendar.current.component(.day, from: Date())
        statusItem.button?.image = makeDateImage(text: String(day))
    }

    /// Renders the day-of-month into a status bar icon.
    private func makeDateImage(text: String) -> NSImage {
        let size = NSSize(width: 28, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()

        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.controlTextColor,
            .paragraphStyle: para
        ]
        let textBounds = (text as NSString).boundingRect(with: size, options: [], attributes: attrs)
        (text as NSString).draw(at: NSPoint(x: 4, y: (size.height - textBounds.height) / 2),
                                withAttributes: attrs)

        image.unlockFocus()
        return image
    }

    private func showLaunchNotification() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.title", comment: "App name shown in notification")
        content.body = NSLocalizedString("notification.body", comment: "Notification body")
        content.sound = nil
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "launch-\(Date().timeIntervalSince1970)",
                                  content: content,
                                  trigger: nil))
    }
}
