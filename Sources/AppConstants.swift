import AppKit
import Foundation

enum AppConstants {
    static let fallbackBundleIdentifier = "com.topcal.app"

    enum Popover {
        static let size = NSSize(width: 240, height: 300)
    }

    enum StatusIcon {
        static let imageSize = NSSize(width: 30, height: 24)
        static let fontSize: CGFloat = 12
        static let lunarFontSize: CGFloat = 8
        static let cornerRadius: CGFloat = 3
        static let borderWidth: CGFloat = 1
    }

    enum Calendar {
        static let weekdayFontSize: CGFloat = 10
        static let dayCellFontSize: CGFloat = 12
        static let lunarFontSize: CGFloat = 9
        static let titleFontSize: CGFloat = 13
        static let dayCellHeight: CGFloat = 34
        static let cellSpacing: CGFloat = 2
        static let margin: CGFloat = 10
        static let topPadding: CGFloat = 10
        static let rowSpacing: CGFloat = 4
    }
}
