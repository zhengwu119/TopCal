import AppKit
import Foundation
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var calendarViewController: CalendarViewController!
    private var timer: Timer?
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[MC] applicationDidFinishLaunching called")

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("[MC] StatusItem created, button=\(statusItem.button != nil)")

        guard let button = statusItem.button else {
            print("[MC] FATAL: button is nil")
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
        popover.delegate = self
        print("[MC] Popover ready")

        // Timer
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateDateDisplay()
        }

        // Launch at login
        LaunchAtLoginManager.shared.register()
        print("[MC] LaunchAgent registered")

        // Notification
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted { self.showLaunchNotification() }
            }
        }

        print("[MC] Done — date should be visible in menu bar")
    }

    @objc private func togglePopover(_ sender: Any?) {
        print("[MC] togglePopover called, isShown=\(popover.isShown)")
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    private func showPopover(_ sender: Any?) {
        guard let button = statusItem.button else {
            print("[MC] showPopover: button is nil")
            return
        }
        print("[MC] showPopover: button bounds=\(button.bounds)")
        calendarViewController.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        print("[MC] showPopover: popover.show called, isShown=\(popover.isShown)")
    }

    private func closePopover(_ sender: Any?) {
        print("[MC] closePopover called")
        popover.performClose(sender)
    }

    private func updateDateDisplay() {
        let day = Calendar.current.component(.day, from: Date())
        let text = String(day)
        statusItem.button?.image = makeDateImage(text: text)
        print("[MC] Updated to day \(text)")
    }

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
        let r = (text as NSString).boundingRect(with: size, options: [], attributes: attrs)
        (text as NSString).draw(at: NSPoint(x: 4, y: (size.height - r.height) / 2), withAttributes: attrs)

        image.unlockFocus()
        return image
    }

    private func showLaunchNotification() {
        let c = UNMutableNotificationContent()
        c.title = "日历已就绪"
        c.body = "点击菜单栏日期查看日历"
        c.sound = nil
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "launch-\(Date().timeIntervalSince1970)", content: c, trigger: nil))
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidShow(_ notification: Notification) {
        print("[MC] popoverDidShow")
    }
    func popoverDidClose(_ notification: Notification) {
        print("[MC] popoverDidClose")
    }
}
