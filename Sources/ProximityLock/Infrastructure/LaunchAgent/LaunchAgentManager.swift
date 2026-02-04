import Foundation

final class LaunchAgentManager: LaunchAgentManaging {

    private let plistPath: String
    private let fileManager: FileManager

    init(plistPath: String = Constants.LaunchAgent.plistPath, fileManager: FileManager = .default) {
        self.plistPath = plistPath
        self.fileManager = fileManager
    }

    func install(executablePath: String) throws {
        let plist: [String: Any] = [
            "Label": Constants.LaunchAgent.label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false,
            "StandardOutPath": "/tmp/proximity-lock.log",
            "StandardErrorPath": "/tmp/proximity-lock-error.log"
        ]

        let directory = (plistPath as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: directory) {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: URL(fileURLWithPath: plistPath))

        Log.app.info("LaunchAgent installed at \(self.plistPath)")
    }

    func uninstall() throws {
        guard fileManager.fileExists(atPath: plistPath) else { return }
        try fileManager.removeItem(atPath: plistPath)
        Log.app.info("LaunchAgent removed from \(self.plistPath)")
    }

    func isInstalled() -> Bool {
        fileManager.fileExists(atPath: plistPath)
    }
}
