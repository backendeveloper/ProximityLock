import Foundation

struct SignalReading: Equatable {
    let rssi: Double
    let timestamp: Date

    init(rssi: Double, timestamp: Date = Date()) {
        self.rssi = rssi
        self.timestamp = timestamp
    }
}
