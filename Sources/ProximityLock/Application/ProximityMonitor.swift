import Foundation

final class ProximityMonitor {

    private let scanner: BluetoothScanning
    private let screenLocker: ScreenLocking
    private let configStore: ConfigurationStore
    private let stateMachine: ProximityStateMachine
    private let bluetoothObserver: BluetoothStateObserver

    private var emaFilter: ExponentialMovingAverage
    private var hysteresisEvaluator: HysteresisEvaluator

    var onStateChange: ((ProximityState) -> Void)?
    var onSignalUpdate: ((Double, Double) -> Void)?

    private(set) var currentFilteredRSSI: Double?
    private(set) var currentRawRSSI: Double?

    init(
        scanner: BluetoothScanning,
        screenLocker: ScreenLocking,
        configStore: ConfigurationStore,
        stateMachine: ProximityStateMachine,
        bluetoothObserver: BluetoothStateObserver
    ) {
        self.scanner = scanner
        self.screenLocker = screenLocker
        self.configStore = configStore
        self.stateMachine = stateMachine
        self.bluetoothObserver = bluetoothObserver

        let config = configStore.configuration
        self.emaFilter = ExponentialMovingAverage(alpha: config.emaAlpha)
        self.hysteresisEvaluator = HysteresisEvaluator(
            lockThreshold: config.lockThreshold,
            presentThreshold: config.presentThreshold
        )

        setupBindings()
    }

    func start() {
        Log.app.info("ProximityMonitor starting")
        scanner.startScanning()
        configStore.startWatching()
    }

    func stop() {
        Log.app.info("ProximityMonitor stopping")
        scanner.stopScanning()
        configStore.stopWatching()
        stateMachine.reset()
        emaFilter.reset()
    }

    private func setupBindings() {
        scanner.delegate = self

        stateMachine.onStateChange = { [weak self] newState in
            guard let self else { return }
            self.onStateChange?(newState)

            if newState == .away {
                guard self.configStore.configuration.enabled else {
                    Log.app.info("Lock skipped: monitoring disabled")
                    return
                }
                self.screenLocker.lockScreen()
            }
        }

        bluetoothObserver.onBluetoothOff = { [weak self] in
            guard let self else { return }
            if self.configStore.configuration.lockOnBluetoothDisable {
                self.stateMachine.bluetoothOff()
            }
        }

        bluetoothObserver.onBluetoothOn = { [weak self] in
            self?.scanner.startScanning()
        }

        configStore.onConfigurationChange = { [weak self] newConfig in
            self?.applyConfiguration(newConfig)
        }
    }

    private func applyConfiguration(_ config: AppConfiguration) {
        emaFilter = ExponentialMovingAverage(alpha: config.emaAlpha)
        hysteresisEvaluator = HysteresisEvaluator(
            lockThreshold: config.lockThreshold,
            presentThreshold: config.presentThreshold
        )
        stateMachine.updateTimeouts(
            lockTimeout: config.lockTimeout,
            signalLossTimeout: config.signalLossTimeout
        )
        Log.config.info("Applied new configuration")
    }

    private func processReading(_ rssi: Double) {
        currentRawRSSI = rssi
        let filtered = emaFilter.update(with: rssi)
        currentFilteredRSSI = filtered

        let result = hysteresisEvaluator.evaluate(filteredRSSI: filtered)
        stateMachine.processSignal(result)

        onSignalUpdate?(rssi, filtered)

        Log.signal.debug("RSSI raw=\(rssi, format: .fixed(precision: 1)) filtered=\(filtered, format: .fixed(precision: 1)) → \(String(describing: result))")
    }
}

extension ProximityMonitor: BluetoothScanningDelegate {

    func scanner(_ scanner: BluetoothScanning, didDiscover device: WatchDevice, rssi: Double) {
        let config = configStore.configuration

        if let targetId = config.watchIdentifier {
            guard device.id.uuidString == targetId else { return }
        }

        processReading(rssi)
    }

    func scanner(_ scanner: BluetoothScanning, didUpdateState isPoweredOn: Bool) {
        bluetoothObserver.updateState(isPoweredOn: isPoweredOn)
    }
}
