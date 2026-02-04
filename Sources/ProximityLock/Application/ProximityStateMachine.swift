import Foundation

final class ProximityStateMachine: ProximityDeciding {

    private(set) var currentState: ProximityState = .unknown
    var onStateChange: ((ProximityState) -> Void)?

    private var lockTimer: Timer?
    private var lockTimeout: TimeInterval
    private var signalLossTimeout: TimeInterval
    private var signalLossTimer: Timer?

    init(lockTimeout: TimeInterval, signalLossTimeout: TimeInterval) {
        self.lockTimeout = lockTimeout
        self.signalLossTimeout = signalLossTimeout
    }

    func updateTimeouts(lockTimeout: TimeInterval, signalLossTimeout: TimeInterval) {
        self.lockTimeout = lockTimeout
        self.signalLossTimeout = signalLossTimeout
    }

    func processSignal(_ result: HysteresisResult) {
        cancelSignalLossTimer()
        startSignalLossTimer()

        switch (currentState, result) {
        case (.unknown, .abovePresent):
            transition(to: .present)

        case (.present, .belowLock):
            transition(to: .warning)
            startLockTimer()

        case (.present, _):
            break

        case (.warning, .abovePresent):
            cancelLockTimer()
            transition(to: .present)

        case (.warning, .belowLock):
            break

        case (.warning, .inGap):
            break

        case (.away, .abovePresent):
            transition(to: .present)

        case (.away, _):
            break

        case (.unknown, .belowLock):
            transition(to: .away)

        case (.unknown, .inGap):
            break
        }
    }

    func signalLost() {
        cancelLockTimer()
        cancelSignalLossTimer()

        switch currentState {
        case .present, .warning:
            transition(to: .away)
        case .unknown, .away:
            break
        }
    }

    func bluetoothOff() {
        cancelLockTimer()
        cancelSignalLossTimer()
        transition(to: .away)
    }

    func reset() {
        cancelLockTimer()
        cancelSignalLossTimer()
        transition(to: .unknown)
    }

    private func transition(to newState: ProximityState) {
        guard newState != currentState else { return }
        let oldState = currentState
        currentState = newState
        Log.state.info("State: \(oldState.rawValue) → \(newState.rawValue)")
        onStateChange?(newState)
    }

    private func startLockTimer() {
        cancelLockTimer()
        lockTimer = Timer.scheduledTimer(withTimeInterval: lockTimeout, repeats: false) { [weak self] _ in
            guard let self, self.currentState == .warning else { return }
            Log.state.info("Lock timeout expired")
            self.transition(to: .away)
        }
    }

    private func cancelLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
    }

    private func startSignalLossTimer() {
        cancelSignalLossTimer()
        signalLossTimer = Timer.scheduledTimer(withTimeInterval: signalLossTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }
            Log.state.info("Signal loss timeout expired")
            self.signalLost()
        }
    }

    private func cancelSignalLossTimer() {
        signalLossTimer?.invalidate()
        signalLossTimer = nil
    }
}
