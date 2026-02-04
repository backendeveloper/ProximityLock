import Foundation

final class StatusBarViewModel {

    var onUpdate: (() -> Void)?

    private(set) var state: ProximityState = .unknown
    private(set) var signalStrength: Double?
    private(set) var filteredSignal: Double?
    private(set) var watchName: String?
    private(set) var isEnabled: Bool = true
    private(set) var isLaunchAtLogin: Bool = false
    private(set) var discoveredDevices: [WatchDevice] = []
    private(set) var selectedWatchId: String?

    var signalDescription: String {
        guard let signal = filteredSignal else { return "No signal" }
        let rounded = Int(signal.rounded())
        return "\(rounded) dBm"
    }

    var signalBarCount: Int {
        guard let signal = filteredSignal else { return 0 }
        switch signal {
        case (-50)...: return 5
        case (-60)..<(-50): return 4
        case (-70)..<(-60): return 3
        case (-80)..<(-70): return 2
        case (-90)..<(-80): return 1
        default: return 0
        }
    }

    var signalQuality: String {
        switch signalBarCount {
        case 5: return "Excellent"
        case 4: return "Strong"
        case 3: return "Good"
        case 2: return "Weak"
        case 1: return "Very Weak"
        default: return "None"
        }
    }

    var stateDescription: String {
        switch state {
        case .present: return "Present"
        case .warning: return "Warning"
        case .away: return "Away"
        case .unknown: return "Searching..."
        }
    }

    func updateState(_ newState: ProximityState) {
        state = newState
        onUpdate?()
    }

    func updateSignal(raw: Double, filtered: Double) {
        signalStrength = raw
        filteredSignal = filtered
        onUpdate?()
    }

    func updateConfiguration(_ config: AppConfiguration) {
        isEnabled = config.enabled
        isLaunchAtLogin = config.launchAtLogin
        watchName = config.watchName
        selectedWatchId = config.watchIdentifier
        onUpdate?()
    }

    func updateDiscoveredDevices(_ devices: [WatchDevice]) {
        discoveredDevices = devices
        onUpdate?()
    }
}
