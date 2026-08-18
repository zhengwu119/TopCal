import Foundation

/// Official Chinese public holidays and make-up workdays (调休补班).
///
/// Data is entered per year from the State Council's annual holiday notice
/// (国务院办公厅关于部分节假日安排的通知). Markers and hover tooltips are
/// enabled by default.
///
/// Dates are stored as `YYYYMMDD` integers to avoid timezone pitfalls.
/// Please add new years' data when the official notice is published.
enum HolidayCalendar {
    /// 法定节假日（放假）— date keys as YYYYMMDD → holiday name (Chinese).
    private static let holidaysByYear: [Int: [Int: String]] = [
        2026: [
            // 元旦 1/1–1/3
            20260101: "元旦", 20260102: "元旦", 20260103: "元旦",
            // 春节 2/15–2/23
            20260215: "春节", 20260216: "春节", 20260217: "春节",
            20260218: "春节", 20260219: "春节", 20260220: "春节",
            20260221: "春节", 20260222: "春节", 20260223: "春节",
            // 清明 4/4–4/6
            20260404: "清明节", 20260405: "清明节", 20260406: "清明节",
            // 劳动节 5/1–5/5
            20260501: "劳动节", 20260502: "劳动节", 20260503: "劳动节",
            20260504: "劳动节", 20260505: "劳动节",
            // 端午 6/19–6/21
            20260619: "端午节", 20260620: "端午节", 20260621: "端午节",
            // 中秋 9/25–9/27
            20260925: "中秋节", 20260926: "中秋节", 20260927: "中秋节",
            // 国庆 10/1–10/7
            20261001: "国庆节", 20261002: "国庆节", 20261003: "国庆节",
            20261004: "国庆节", 20261005: "国庆节", 20261006: "国庆节",
            20261007: "国庆节"
        ]
    ]

    /// 调休上班日（周末补班）— date keys as YYYYMMDD → associated holiday.
    private static let makeupWorkdaysByYear: [Int: [Int: String]] = [
        2026: [
            20260104: "元旦",  // 1/4 (Sun) after New Year
            20260214: "春节",  // 2/14 (Sat) before Spring Festival
            20260228: "春节",  // 2/28 (Sat) after Spring Festival
            20260509: "劳动节", // 5/9 (Sat) after Labour Day
            20260920: "中秋节", // 9/20 (Sun) before Mid-Autumn
            20261010: "国庆节"  // 10/10 (Sat) after National Day
        ]
    ]

    /// English names for the (Chinese) holiday names, used when the UI
    /// language is not Chinese.
    private static let englishNames: [String: String] = [
        "元旦": "New Year's Day",
        "春节": "Spring Festival",
        "清明节": "Qingming Festival",
        "劳动节": "Labour Day",
        "端午节": "Dragon Boat Festival",
        "中秋节": "Mid-Autumn Festival",
        "国庆节": "National Day"
    ]

    /// 法定节假日（公休日）→ green dot.
    static func isPublicHoliday(_ date: Date) -> Bool {
        guard shouldShow() else { return false }
        return holidayName(for: date) != nil
    }

    /// 调休上班日（周末补班）→ neutral dot.
    static func isMakeupWorkday(_ date: Date) -> Bool {
        guard shouldShow() else { return false }
        return makeupName(for: date) != nil
    }

    /// Hover tooltip for a holiday cell, e.g. "国庆节 · 放假".
    static func holidayTooltip(for date: Date) -> String? {
        guard shouldShow(), let name = holidayName(for: date) else { return nil }
        return tooltip(name: name, key: "holiday.tooltip",
                       fallback: "%@ · Public Holiday")
    }

    /// Hover tooltip for a make-up workday cell, e.g. "国庆节 · 调休上班".
    static func makeupTooltip(for date: Date) -> String? {
        guard shouldShow(), let name = makeupName(for: date) else { return nil }
        return tooltip(name: name, key: "makeup.tooltip",
                       fallback: "%@ · Make-up Workday")
    }

    /// Raw (Chinese) statutory-holiday name for a date, or nil.
    /// Used by the view controller to avoid repeating the festival name
    /// when a special-festival tooltip line is appended. Mirrors
    /// `holidayTooltip`'s `shouldShow()` gate so that when the holiday
    /// markers are off the festival line keeps its own name.
    static func holidayNamePublic(for date: Date) -> String? {
        guard shouldShow() else { return nil }
        return holidayName(for: date)
    }

    /// Raw (Chinese) make-up workday's associated holiday name, or nil.
    /// Same `shouldShow()` gate as `makeupTooltip` — see `holidayNamePublic`.
    static func makeupNamePublic(for date: Date) -> String? {
        guard shouldShow() else { return nil }
        return makeupName(for: date)
    }

    // MARK: - Helpers

    private static func holidayName(for date: Date) -> String? {
        let parts = ymdParts(date)
        return holidaysByYear[parts.year]?[parts.ymd]
    }

    private static func makeupName(for date: Date) -> String? {
        let parts = ymdParts(date)
        return makeupWorkdaysByYear[parts.year]?[parts.ymd]
    }

    private static func tooltip(name: String, key: String, fallback: String) -> String {
        let localizedName = LocaleProvider.isChinese ? name : (englishNames[name] ?? name)
        let template = LocaleProvider.localizedString(key, fallback: fallback)
        return String(format: template, localizedName)
    }

    /// Whether holiday markers should be shown.
    ///
    /// Enabled by default (matching the lunar overlay); the `LunarForceShow`
    /// flag used by the renderer can force it off/on explicitly.
    private static func shouldShow() -> Bool {
        if UserDefaults.standard.object(forKey: LunarCalendar.lunarForceShowKey) != nil {
            return UserDefaults.standard.bool(forKey: LunarCalendar.lunarForceShowKey)
        }
        return true
    }

    private static func ymdParts(_ date: Date) -> (year: Int, ymd: Int) {
        let comps = LocaleProvider.calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 0
        return (year, year * 10000 + (comps.month ?? 0) * 100 + (comps.day ?? 0))
    }
}
