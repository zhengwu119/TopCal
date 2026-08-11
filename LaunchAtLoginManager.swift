import Foundation
import AppKit

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private var launchAgentDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private var launchAgentFile: URL {
        launchAgentDirectory.appendingPathComponent("com.workbuddy.menubarcalendar.plist")
    }

    var isEnabled: Bool {
        return FileManager.default.fileExists(atPath: launchAgentFile.path)
    }

    func register() {
        // Already registered
        if isEnabled { return }

        // Ensure LaunchAgents directory exists
        try? FileManager.default.createDirectory(at: launchAgentDirectory, withIntermediateDirectories: true)

        // Build the plist
        let appPath = Bundle.main.bundlePath
        let plist: [String: Any] = [
            "Label": "com.workbuddy.menubarcalendar",
            "ProgramArguments": [appPath],
            "RunAtLoad": true,
            "KeepAlive": false,
            "StandardOutPath": "/dev/null",
            "StandardErrorPath": "/dev/null"
        ]

        let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try? data?.write(to: launchAgentFile)

        // Load the agent
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["load", launchAgentFile.path]
        try? task.run()
    }

    func unregister() {
        guard isEnabled else { return }

        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["unload", launchAgentFile.path]
        try? task.run()

        try? FileManager.default.removeItem(at: launchAgentFile)
    }
}
