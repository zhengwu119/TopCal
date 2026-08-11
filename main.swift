import AppKit
import Foundation

// MARK: - main.swift (explicit entry point, NOT @main)
// On macOS 26 / Swift 6.2, @main silently fails to invoke applicationDidFinishLaunching.
// We use explicit top-level code instead, which is proven to work.

print("[MC] Launching...")

let appDelegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()
