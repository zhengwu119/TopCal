import AppKit

/// App appearance (theme) management: follow-system / light / dark.
///
/// The choice is persisted in `UserDefaults` under `Appearance` and applied
/// to `NSApp.appearance`. `nil` means "follow the system", which is the
/// default.
enum AppearanceManager {
    enum Mode: String {
        case system
        case light
        case dark
    }

    static let preferenceKey = "Appearance"

    /// The user's chosen mode (defaults to `.system`).
    static var current: Mode {
        guard let raw = UserDefaults.standard.string(forKey: preferenceKey) else { return .system }
        return Mode(rawValue: raw) ?? .system
    }

    /// The appearance currently applied to the app (nil = follow system).
    static var appearance: NSAppearance? {
        NSApp.appearance
    }

    /// Applies the stored appearance to the running app.
    static func apply() {
        switch current {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }
}
