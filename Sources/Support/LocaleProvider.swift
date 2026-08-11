import Foundation

/// Centralised locale/calendar source and per-app language selection.
///
/// - `forcedLocale` / `forcedDateFormat` are hooks for the screenshot renderer
///   and tests; the app never sets them.
/// - `userLanguage` is the language the user picked in the settings menu,
///   persisted in `UserDefaults` under `"UserLanguage"`. When set, the UI
///   renders in that language regardless of the macOS system language.
enum LocaleProvider {
    struct AppLanguage {
        let code: String
        let displayName: String
    }

    /// All languages TopCal ships (matches the *.lproj bundles).
    static let supportedLanguages: [AppLanguage] = [
        .init(code: "en", displayName: "English"),
        .init(code: "zh-Hans", displayName: "简体中文"),
        .init(code: "zh-Hant", displayName: "繁體中文"),
        .init(code: "ja", displayName: "日本語"),
        .init(code: "ko", displayName: "한국어"),
        .init(code: "de", displayName: "Deutsch"),
        .init(code: "fr", displayName: "Français"),
        .init(code: "es", displayName: "Español")
    ]

    static let userLanguageKey = "UserLanguage"

    /// Render/test-only override. `nil` in production.
    static var forcedLocale: Locale?

    /// Render-only: forces `MonthGrid.formattedTitle`'s date format string
    /// (bypasses the bundle's NSLocalizedString resolution, which the render
    /// tool can't control). `nil` in production.
    static var forcedDateFormat: String?

    /// The user-selected language code ("en", "zh-Hans", …) or nil.
    static var userLanguage: String? {
        get { UserDefaults.standard.string(forKey: userLanguageKey) }
        set { UserDefaults.standard.set(newValue, forKey: userLanguageKey) }
    }

    /// The language code currently in effect (user pick → system → en).
    static var currentLanguage: String {
        userLanguage ?? systemLanguageCode
    }

    /// "zh" prefix from the system (or user) language, used to default the
    /// month-title format and some UI strings.
    static var isChinese: Bool {
        currentLanguage.hasPrefix("zh")
    }

    static var locale: Locale {
        if let forced = forcedLocale { return forced }
        if let lang = userLanguage { return Locale(identifier: lang) }
        return Locale.autoupdatingCurrent
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar
    }

    /// Looks up `key` in the *current* language's Localizable.strings.
    ///
    /// The settings menu can switch the app language at runtime, which
    /// NSLocalizedString can't reflect (it follows the macOS system language),
    /// so UI strings that must follow the in-app language go through here.
    static func localizedString(_ key: String, fallback: String) -> String {
        let lang = currentLanguage
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings",
                                       inDirectory: "\(lang).lproj"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: String],
           let value = dict[key] {
            return value
        }
        return fallback
    }

    private static var systemLanguageCode: String {
        let code = Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        return code.hasPrefix("zh") ? "zh-Hans" : code
    }
}
