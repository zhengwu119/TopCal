import AppKit
import Foundation

enum AppConstants {
    static let fallbackBundleIdentifier = "com.topcal.app"

    enum Popover {
        static let size = NSSize(width: 240, height: 270)
    }

    enum StatusIcon {
        static let imageSize = NSSize(width: 28, height: 22)
        static let fontSize: CGFloat = 13
        static let leftInset: CGFloat = 4
    }

    enum Calendar {
        static let weekdayFontSize: CGFloat = 10
        static let dayCellFontSize: CGFloat = 12
        static let dayCellFontWeight: NSFont.Weight = .regular
        static let titleFontSize: CGFloat = 13
        static let dayCellHeight: CGFloat = 26
        static let cellSpacing: CGFloat = 2
        static let margin: CGFloat = 10
        static let topPadding: CGFloat = 10
        static let rowSpacing: CGFloat = 4
    }
}