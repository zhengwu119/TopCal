import AppKit
import Foundation
import UserNotifications

/// Wraps UserNotifications for the optional post-launch confirmation.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    /// Requests notification permission and, if granted, posts a single
    /// "I'm running" notification. Safe to call at every launch.
    func requestPermissionAndNotifyLaunch() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                if granted { self?.fireLaunchNotification() }
            }
        }
    }

    private func fireLaunchNotification() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.title", comment: "App name shown in notification")
        content.body = NSLocalizedString("notification.body", comment: "Notification body")
        content.sound = nil
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "launch-\(Date().timeIntervalSince1970)",
                                  content: content,
                                  trigger: nil))
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the launch notification even when the app is in the foreground.
        completionHandler([.banner])
    }
}