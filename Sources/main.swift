import AppKit
import Foundation

// MARK: - main.swift (explicit entry point, NOT @main)
// On macOS 26 / Swift 6.2, `@main` on NSApplicationDelegate subclasses silently
// fails to invoke applicationDidFinishLaunching. Explicit top-level code is
// reliable across macOS versions.

let appDelegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()