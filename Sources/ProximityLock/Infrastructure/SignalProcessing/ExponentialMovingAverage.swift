struct ExponentialMovingAverage: SignalFiltering {
    private let alpha: Double
    private(set) var currentValue: Double?

    init(alpha: Double) {
        precondition(alpha > 0 && alpha <= 1, "Alpha must be in (0, 1]")
        self.alpha = alpha
    }

    mutating func update(with value: Double) -> Double {
        guard let previous = currentValue else {
            currentValue = value
            return value
        }
        let filtered = alpha * value + (1 - alpha) * previous
        currentValue = filtered
        return filtered
    }

    mutating func reset() {
        currentValue = nil
    }
}
