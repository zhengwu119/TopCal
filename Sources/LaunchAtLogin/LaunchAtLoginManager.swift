import AppKit
import Foundation
import os.log

private let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? AppConstants.fallbackBundleIdentifier,
                        category: "launch-at-login")

/// Registers the app as a login item by installing a per-user LaunchAgent.
///
/// Uses a `~/Library/LaunchAgents` plist instead of the modern `SMAppService`
/// API so the app can be built and signed ad-hoc (no developer account needed).
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private init() {}

    private var launchAgentIdentifier: String {
        Bundle.main.bundleIdentifier ?? AppConstants.fallbackBundleIdentifier
    }

    private var launchAgentDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private var launchAgentFile: URL {
        launchAgentDirectory.appendingPathComponent("\(launchAgentIdentifier).plist")
    }

    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: launchAgentFile.path)
    }

    /// Installs the LaunchAgent and loads it with launchctl. Safe to call
    /// multiple times — no-op if already registered.
    func register() {
        if isEnabled { return }

        do {
            try FileManager.default.createDirectory(at: launchAgentDirectory,
                                                    withIntermediateDirectories: true)

            let plist: [String: Any] = [
                "Label": launchAgentIdentifier,
                "ProgramArguments": [Bundle.main.bundlePath],
                "RunAtLoad": true,
                "KeepAlive": false,
                "StandardOutputPath": "/dev/null",
                "StandardErrorPath": "/dev/null"
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: plist,
                                                          format: .xml,
                                                          options: 0)
            try data.write(to: launchAgentFile)

            try runLaunchctl(arguments: ["bootstrap", "gui/\(getuid())", launchAgentFile.path])
        } catch {
            os_log("Failed to register launch agent: %@", log: log, type: .error,
                   error.localizedDescription)
        }
    }

    /// Removes the LaunchAgent plist and unloads it.
    func unregister() {
        guard isEnabled else { return }
        try? runLaunchctl(arguments: ["bootout", "gui/\(getuid())", launchAgentFile.path])
        try? FileManager.default.removeItem(at: launchAgentFile)
    }

    /// Runs /bin/launchctl with the given arguments, silencing its output.
    /// Non-zero exit status is logged as info) since "already loaded" is harmless.
    private func runLaunchctl(arguments: [String]) throws {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = arguments
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try task.run()
        task.waitUntilExit()
        if task.terminationStatus != 0 {
            os_log("launchctl %{public}@ exited %d (likely harmless if already loaded)",
                   log: log, type: .info, arguments.first ?? "?", task.terminationStatus)
        }
    }
}