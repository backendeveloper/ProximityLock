import os

enum Log {
    private static let subsystem = Constants.bundleIdentifier

    static let bluetooth = Logger(subsystem: subsystem, category: "bluetooth")
    static let signal = Logger(subsystem: subsystem, category: "signal")
    static let state = Logger(subsystem: subsystem, category: "state")
    static let lock = Logger(subsystem: subsystem, category: "lock")
    static let config = Logger(subsystem: subsystem, category: "config")
    static let app = Logger(subsystem: subsystem, category: "app")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
