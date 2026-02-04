import Foundation

enum Constants {
    static let bundleIdentifier = "com.proximity-lock"
    static let appName = "ProximityLock"

    enum Config {
        static let directoryName = "proximity-lock"
        static let fileName = "config.json"
        static let directoryPath: String = {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return "\(home)/.config/\(directoryName)"
        }()
        static let filePath: String = {
            return "\(directoryPath)/\(fileName)"
        }()
    }

    enum LaunchAgent {
        static let label = "com.proximity-lock.agent"
        static let plistFileName = "\(label).plist"
        static let plistPath: String = {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return "\(home)/Library/LaunchAgents/\(plistFileName)"
        }()
    }

    enum Bluetooth {
        static let appleCompanyIdentifier: UInt16 = 0x004C
    }

    enum Defaults {
        static let lockThreshold: Double = -80
        static let presentThreshold: Double = -55
        static let lockTimeout: TimeInterval = 12
        static let signalLossTimeout: TimeInterval = 20
        static let emaAlpha: Double = 0.3
        static let scanInterval: TimeInterval = 2.0
        static let adaptiveScanInterval: TimeInterval = 1.0
    }
}
