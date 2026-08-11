import AppKit

/// Renders the day-of-month text into an NSImage suitable for a status bar item.
/// Drawing into an image is more reliable than `button.title` on recent macOS.
enum StatusBarIconRenderer {
    static func image(for date: Date = Date()) -> NSImage {
        let day = Calendar.current.component(.day, from: date)
        return makeImage(text: String(day))
    }

    static func makeImage(text: String) -> NSImage {
        let size = AppConstants.StatusIcon.imageSize
        let image = NSImage(size: size)
        image.lockFocus()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: AppConstants.StatusIcon.fontSize,
                                                     weight: .medium),
            .foregroundColor: NSColor.controlTextColor,
            .paragraphStyle: paragraph
        ]
        let textBounds = (text as NSString).boundingRect(with: size, options: [], attributes: attrs)
        (text as NSString).draw(at: NSPoint(x: AppConstants.StatusIcon.leftInset,
                                            y: (size.height - textBounds.height) / 2),
                                withAttributes: attrs)
        image.unlockFocus()
        return image
    }
}