protocol ProximityDeciding: AnyObject {
    var currentState: ProximityState { get }
    var onStateChange: ((ProximityState) -> Void)? { get set }
    func processSignal(_ result: HysteresisResult)
    func signalLost()
    func bluetoothOff()
    func reset()
}
