import AppKit
import Foundation

// NOTE: We deliberately avoid the `@main` attribute here.
// On macOS 26 / Swift 6.2, `@main` on an NSApplicationDelegate subclass
// silently fails to invoke `applicationDidFinishLaunching` (the process
// is killed before the delegate is wired up). Explicit top-level code
// that creates the NSApplication manually is reliable on all versions.

let appDelegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()
