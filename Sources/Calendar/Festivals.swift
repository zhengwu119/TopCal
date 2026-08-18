import Foundation

/// A single special-festival entry used for hover tooltips on day cells.
struct Festival {
    let name: String           // 中文名
    let englishName: String
    let blurb: String          // 一句话中文说明
    let englishBlurb: String

    var localizedName: String { LocaleProvider.isChinese ? name : englishName }
    var localizedBlurb: String { LocaleProvider.isChinese ? blurb : englishBlurb }
}

/// Special-festival lookup for hover tooltips.
///
/// Covers two families:
/// 1. Fixed Gregorian dates (情人节 2/14, 圣诞节 12/25, …)
/// 2. Lunar (Chinese) dates (元宵节 正月十五, 重阳节 九月初九, 除夕, …)
///
/// The 24 solar terms are intentionally not included — computing them
/// accurately requires astronomical math and doesn't fit a tooltip feature.
///
/// When a day is also a statutory holiday / make-up workday (see
/// `HolidayCalendar`), the two tooltip lines are merged by the view
/// controller; if both refer to the same festival, only the blurb is
/// repeated (the name is not).
enum Festivals {
    /// Fixed Gregorian festivals: (month * 100 + day) → festival.
    private static let fixedByMonthDay: [Int: Festival] = [
        101:  Festival(name: "元旦", englishName: "New Year's Day",
                       blurb: "公历新年的第一天",
                       englishBlurb: "The first day of the Gregorian year"),
        214:  Festival(name: "情人节", englishName: "Valentine's Day",
                       blurb: "西方情人节，互赠礼物表达爱意",
                       englishBlurb: "Western festival of love; gifts and cards are exchanged"),
        308:  Festival(name: "三八国际妇女节", englishName: "International Women's Day",
                       blurb: "庆祝女性的贡献与权益",
                       englishBlurb: "Celebrating women's contributions and rights"),
        312:  Festival(name: "植树节", englishName: "Arbor Day",
                       blurb: "鼓励植树造林、绿化环境",
                       englishBlurb: "Encourages tree planting and greening"),
        401:  Festival(name: "愚人节", englishName: "April Fools' Day",
                       blurb: "以轻松玩笑为主题的节日",
                       englishBlurb: "A day of light-hearted pranks"),
        504:  Festival(name: "五四青年节", englishName: "Youth Day",
                       blurb: "纪念 1919 年五四运动",
                       englishBlurb: "Commemorates the 1919 May Fourth Movement"),
        601:  Festival(name: "六一儿童节", englishName: "Children's Day",
                       blurb: "属于孩子们的节日",
                       englishBlurb: "A festival for children"),
        801:  Festival(name: "八一建军节", englishName: "Army Day",
                       blurb: "纪念中国人民解放军的建军",
                       englishBlurb: "Commemorates the founding of the PLA"),
        910:  Festival(name: "教师节", englishName: "Teachers' Day",
                       blurb: "感谢师恩、尊师重教",
                       englishBlurb: "A day to honour teachers"),
        1031: Festival(name: "万圣节", englishName: "Halloween",
                       blurb: "西方传统：南瓜灯、变装派对",
                       englishBlurb: "Western tradition: jack-o'-lanterns and costume parties"),
        1111: Festival(name: "光棍节", englishName: "Singles' Day",
                       blurb: "起源于中国的非官方节日",
                       englishBlurb: "Unofficial festival that began in China"),
        1224: Festival(name: "平安夜", englishName: "Christmas Eve",
                       blurb: "圣诞前夜，西方传统守夜",
                       englishBlurb: "The evening before Christmas"),
        1225: Festival(name: "圣诞节", englishName: "Christmas",
                       blurb: "西方最隆重的节日",
                       englishBlurb: "The biggest Western holiday"),
        1231: Festival(name: "跨年夜", englishName: "New Year's Eve",
                       blurb: "迎接新年的前夜",
                       englishBlurb: "The eve of the New Year")
    ]

    /// Lunar festivals: (lunarMonth * 100 + lunarDay) → festival.
    /// Statutory holidays (春节/端午/中秋) are included so their blurb
    /// still shows next to the holiday tooltip line.
    private static let lunarByMonthDay: [Int: Festival] = [
        101:  Festival(name: "春节", englishName: "Spring Festival",
                       blurb: "农历新年，团圆守岁",
                       englishBlurb: "Lunar New Year: reunion dinner and staying up late"),
        115:  Festival(name: "元宵节", englishName: "Lantern Festival",
                       blurb: "正月十五，吃元宵、赏花灯、猜灯谜",
                       englishBlurb: "15th of the first lunar month: tangyuan, lanterns and riddles"),
        505:  Festival(name: "端午节", englishName: "Dragon Boat Festival",
                       blurb: "农历五月初五，赛龙舟、吃粽子",
                       englishBlurb: "5th of the 5th lunar month: dragon boats and zongzi"),
        707:  Festival(name: "七夕节", englishName: "Qixi Festival",
                       blurb: "农历七月初七，中国情人节",
                       englishBlurb: "7th of the 7th lunar month; China's Valentine's Day"),
        815:  Festival(name: "中秋节", englishName: "Mid-Autumn Festival",
                       blurb: "农历八月十五，赏月吃月饼",
                       englishBlurb: "15th of the 8th lunar month: mooncakes under the full moon"),
        909:  Festival(name: "重阳节", englishName: "Double Ninth Festival",
                       blurb: "农历九月初九，登高赏菊、敬老",
                       englishBlurb: "9th of the 9th lunar month: hill climbing, chrysanthemums, respecting elders"),
        1208: Festival(name: "腊八节", englishName: "Laba Festival",
                       blurb: "农历腊月初八，喝腊八粥",
                       englishBlurb: "8th of the 12th lunar month: Laba porridge")
    ]

    /// 除夕 — the day before the first day of the lunar new year.
    private static let chuxi = Festival(name: "除夕", englishName: "Lunar New Year's Eve",
                                        blurb: "年夜饭、守岁、贴春联",
                                        englishBlurb: "family reunion dinner, staying up late, pasting couplets")

    /// All festivals falling on the given date (fixed Gregorian + lunar).
    static func all(for date: Date) -> [Festival] {
        var result: [Festival] = []

        let comps = LocaleProvider.calendar.dateComponents([.month, .day], from: date)
        if let m = comps.month, let d = comps.day,
           let fixed = fixedByMonthDay[m * 100 + d] {
            result.append(fixed)
        }

        if let lunar = LunarCalendar.components(for: date) {
            if !isLeapMonth(date),
               let lunarFestival = lunarByMonthDay[lunar.month * 100 + lunar.day] {
                result.append(lunarFestival)
            }
            // 除夕 is defined by position (the day before lunar 1/1), so it
            // fires even in the hypothetical case of a leap 12th month.
            if lunar.month == 12, lunar.day >= 29, isLunarNewYearsEve(date) {
                result.append(chuxi)
            }
        }
        return result
    }

    /// Tooltip lines for a date. If `existingChineseName` matches a
    /// festival's (Chinese) name, only the blurb is emitted — used to avoid
    /// repeating the name when the statutory-holiday tooltip already shows it.
    static func tooltipLines(for date: Date, existingChineseName: String?) -> [String] {
        let separator = LocaleProvider.isChinese ? "：" : " — "
        return all(for: date).map { festival in
            festival.name == existingChineseName
                ? festival.localizedBlurb
                : "\(festival.localizedName)\(separator)\(festival.localizedBlurb)"
        }
    }

    // MARK: - Helpers

    /// True when the day after `date` is the 1st of the first lunar month.
    private static func isLunarNewYearsEve(_ date: Date) -> Bool {
        guard let nextDay = LocaleProvider.calendar.date(byAdding: .day, value: 1, to: date),
              let next = LunarCalendar.components(for: nextDay) else { return false }
        return next.month == 1 && next.day == 1
    }

    /// Whether `date` falls in a leap lunar month (闰月).
    ///
    /// Traditional festivals attach to the *regular* month, so a 5/5 landing
    /// in 闰五月 (e.g. 2028-06-27) must NOT trigger 端午 — the real festival
    /// that year is in the regular 五月 (2028-05-28).
    ///
    /// Detection: walk back to the 1st of the containing lunar month; the
    /// month is a leap one iff the day before that 1st still has the same
    /// month number (a leap month repeats the previous month's number).
    private static func isLeapMonth(_ date: Date) -> Bool {
        guard let comps = LunarCalendar.components(for: date), comps.day >= 1,
              let firstDay = LocaleProvider.calendar.date(byAdding: .day, value: 1 - comps.day, to: date),
              let beforeFirst = LocaleProvider.calendar.date(byAdding: .day, value: -1, to: firstDay),
              let previous = LunarCalendar.components(for: beforeFirst) else {
            return false
        }
        return previous.month == comps.month
    }
}
