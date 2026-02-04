protocol SignalFiltering {
    mutating func update(with value: Double) -> Double
    mutating func reset()
    var currentValue: Double? { get }
}

enum HysteresisResult: Equatable {
    case belowLock
    case abovePresent
    case inGap
}

protocol ProximityEvaluating {
    func evaluate(filteredRSSI: Double) -> HysteresisResult
}
