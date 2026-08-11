import AppKit
import Foundation

// Off-screen screenshot renderer for TopCal's README images.
//
// Instantiates the *real* AppKit components (CalendarViewController,
// StatusBarIconRenderer) and renders them to PNG via cacheDisplay, so the
// images show actual layout, fonts, and colors.
//
// Usage:
//   render <locale> <output-dir>
//     locale   en | zh-Hans   (controls weekdays, month title, lunar overlay)
//     output-dir               where screenshot-popover.png and menubar-icon.png go

let args = CommandLine.arguments
let locale = args.count > 1 ? args[1] : "zh-Hans"
let outDir = args.count > 2 ? args[2] : "docs/zh-Hans"
// Optional focus month "yyyy-MM" (defaults to the current month).
let focusMonth: Date? = {
    guard args.count > 3 else { return nil }
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f.date(from: args[3])
}()

// Per-locale rendering config. These mirror the *.lproj/Localizable.strings
// entries but are inlined here because the render bundle can't override
// NSLocalizedString's bundle-resolution behaviour.
let titleFormats = [
    "en": "MMMM yyyy",
    "zh-Hans": "yyyy年M月",
    "zh-Hant": "yyyy年M月",
    "ja": "yyyy年M月",
    "ko": "yyyy년 M월",
    "de": "MMMM yyyy",
    "fr": "MMMM yyyy",
    "es": "MMMM yyyy"
]

LocaleProvider.forcedLocale = Locale(identifier: locale)
LocaleProvider.forcedDateFormat = titleFormats[locale] ?? "MMMM yyyy"
// Belt-and-braces: also force lunar on/off via the UserDefaults hook in
// case LocaleProvider-driven detection ever misses a locale tag.
UserDefaults.standard.set(locale.hasPrefix("zh"), forKey: LunarCalendar.lunarForceShowKey)
UserDefaults.standard.synchronize()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

func savePNG(_ image: NSImage, to path: String) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return }
    let data = rep.representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: path))
    print("saved \(path) (\(rep.pixelsWide)x\(rep.pixelsHigh))")
}

// ------------------------------------------------------------------ popover
let controller = CalendarViewController()
let _ = controller.view
if let focusMonth = focusMonth {
    controller.showMonth(focusMonth)
}
controller.view.frame = NSRect(origin: .zero, size: AppConstants.Popover.size)
controller.view.layoutSubtreeIfNeeded()

let rep = controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds)!
controller.view.cacheDisplay(in: controller.view.bounds, to: rep)
let popoverImage = NSImage(size: controller.view.bounds.size)
popoverImage.addRepresentation(rep)
try savePNG(popoverImage, to: "\(outDir)/screenshot-popover.png")

print("weekdays: \(MonthGrid.weekdaySymbols().joined(separator: " "))")
print("controller title: \(controller.displayedTitle)")

// ------------------------------------------------------------------ icon
let icon = StatusBarIconRenderer.image()
let scaled = NSImage(size: NSSize(width: icon.size.width * 2, height: icon.size.height * 2))
scaled.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
icon.draw(in: NSRect(x: 0, y: 0, width: scaled.size.width, height: scaled.size.height))
scaled.unlockFocus()
try savePNG(scaled, to: "\(outDir)/menubar-icon.png")