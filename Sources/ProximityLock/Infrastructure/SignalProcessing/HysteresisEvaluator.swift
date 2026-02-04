struct HysteresisEvaluator: ProximityEvaluating {
    let lockThreshold: Double
    let presentThreshold: Double

    init(lockThreshold: Double, presentThreshold: Double) {
        precondition(lockThreshold < presentThreshold,
                     "Lock threshold must be less than present threshold")
        self.lockThreshold = lockThreshold
        self.presentThreshold = presentThreshold
    }

    func evaluate(filteredRSSI: Double) -> HysteresisResult {
        if filteredRSSI >= presentThreshold {
            return .abovePresent
        } else if filteredRSSI <= lockThreshold {
            return .belowLock
        } else {
            return .inGap
        }
    }
}
