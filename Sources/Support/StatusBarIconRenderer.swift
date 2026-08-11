import AppKit

/// Renders the status bar item: the day-of-month inside a rounded border,
/// with the lunar date underneath in Chinese locales.
///
/// Drawing into an image is more reliable than `button.title` on recent macOS.
enum StatusBarIconRenderer {
    static func image(for date: Date = Date()) -> NSImage {
        let day = LocaleProvider.calendar.component(.day, from: date)
        return makeImage(day: day, lunar: LunarCalendar.dayLabel(for: date))
    }

    static func makeImage(day: Int, lunar: String?) -> NSImage {
        let size = AppConstants.StatusIcon.imageSize
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)

        // Rounded border
        let border = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: AppConstants.StatusIcon.cornerRadius,
                                  yRadius: AppConstants.StatusIcon.cornerRadius)
        border.lineWidth = AppConstants.StatusIcon.borderWidth
        NSColor.controlTextColor.setStroke()
        border.stroke()

        // Day number
        let dayAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: AppConstants.StatusIcon.fontSize,
                                                     weight: .medium),
            .foregroundColor: NSColor.controlTextColor
        ]
        let dayText = String(day)
        let daySize = dayText.size(withAttributes: dayAttrs)

        if let lunar = lunar {
            // Two lines: day number on top, lunar date below
            dayText.draw(at: NSPoint(x: (size.width - daySize.width) / 2,
                                     y: size.height - daySize.height - 1),
                         withAttributes: dayAttrs)
            let lunarAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: AppConstants.StatusIcon.lunarFontSize,
                                         weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            let lunarSize = lunar.size(withAttributes: lunarAttrs)
            lunar.draw(at: NSPoint(x: (size.width - lunarSize.width) / 2, y: 1),
                       withAttributes: lunarAttrs)
        } else {
            // Single centered line
            dayText.draw(at: NSPoint(x: (size.width - daySize.width) / 2,
                                     y: (size.height - daySize.height) / 2),
                         withAttributes: dayAttrs)
        }

        image.unlockFocus()
        return image
    }
}
