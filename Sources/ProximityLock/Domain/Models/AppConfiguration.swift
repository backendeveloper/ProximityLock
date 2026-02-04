import Foundation

struct AppConfiguration: Codable, Equatable {
    var watchIdentifier: String?
    var watchName: String?
    var lockThreshold: Double
    var presentThreshold: Double
    var lockTimeout: TimeInterval
    var signalLossTimeout: TimeInterval
    var emaAlpha: Double
    var scanInterval: TimeInterval
    var adaptiveScanInterval: TimeInterval
    var enabled: Bool
    var launchAtLogin: Bool
    var lockOnBluetoothDisable: Bool
}
