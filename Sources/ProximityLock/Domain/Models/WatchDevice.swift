import Foundation

struct WatchDevice: Equatable, Identifiable {
    let id: UUID
    let name: String?
    var lastRSSI: Double?
    var lastSeen: Date?
}
