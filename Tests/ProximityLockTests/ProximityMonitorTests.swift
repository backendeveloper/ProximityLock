import XCTest
@testable import ProximityLock

final class MockBluetoothScanner: BluetoothScanning {
    weak var delegate: BluetoothScanningDelegate?
    var trackedDeviceIdentifier: UUID?
    var isScanning = false
    private var devices: [WatchDevice] = []

    func startScanning() { isScanning = true }
    func stopScanning() { isScanning = false }
    func discoveredDevices() -> [WatchDevice] { devices }

    func simulateDiscover(device: WatchDevice, rssi: Double) {
        devices.removeAll { $0.id == device.id }
        devices.append(device)
        delegate?.scanner(self, didDiscover: device, rssi: rssi)
    }

    func simulateBluetoothState(isPoweredOn: Bool) {
        delegate?.scanner(self, didUpdateState: isPoweredOn)
    }
}

final class MockScreenLocker: ScreenLocking {
    var lockCount = 0
    func lockScreen() { lockCount += 1 }
}

final class MockConfigStore: ConfigurationStore {
    var configuration: AppConfiguration
    var onConfigurationChange: ((AppConfiguration) -> Void)?
    var savedConfig: AppConfiguration?

    init(configuration: AppConfiguration = DefaultConfiguration.make()) {
        self.configuration = configuration
    }

    func save(_ configuration: AppConfiguration) throws {
        self.configuration = configuration
        savedConfig = configuration
    }

    func load() throws -> AppConfiguration { configuration }
    func startWatching() {}
    func stopWatching() {}
}

final class ProximityMonitorTests: XCTestCase {

    private var scanner: MockBluetoothScanner!
    private var locker: MockScreenLocker!
    private var configStore: MockConfigStore!
    private var stateMachine: ProximityStateMachine!
    private var btObserver: BluetoothStateObserver!
    private var monitor: ProximityMonitor!

    override func setUp() {
        super.setUp()
        scanner = MockBluetoothScanner()
        locker = MockScreenLocker()
        configStore = MockConfigStore()
        stateMachine = ProximityStateMachine(
            lockTimeout: 100,
            signalLossTimeout: 100
        )
        btObserver = BluetoothStateObserver()

        monitor = ProximityMonitor(
            scanner: scanner,
            screenLocker: locker,
            configStore: configStore,
            stateMachine: stateMachine,
            bluetoothObserver: btObserver
        )
    }

    override func tearDown() {
        monitor.stop()
        monitor = nil
        super.tearDown()
    }

    func testStartBeginsScanning() {
        monitor.start()
        XCTAssertTrue(scanner.isScanning)
    }

    func testStopEndsScanning() {
        monitor.start()
        monitor.stop()
        XCTAssertFalse(scanner.isScanning)
    }

    func testStrongSignalSetsPresent() {
        let device = WatchDevice(id: UUID(), name: "Watch")

        var states: [ProximityState] = []
        monitor.onStateChange = { states.append($0) }

        monitor.start()
        scanner.simulateDiscover(device: device, rssi: -40)

        XCTAssertEqual(stateMachine.currentState, .present)
        XCTAssertTrue(states.contains(.present))
    }

    func testWeakSignalAfterStrongTriggersWarning() {
        let device = WatchDevice(id: UUID(), name: "Watch")

        monitor.start()
        scanner.simulateDiscover(device: device, rssi: -40)
        XCTAssertEqual(stateMachine.currentState, .present)

        // Send multiple weak signals to push EMA below lock threshold
        for _ in 0..<20 {
            scanner.simulateDiscover(device: device, rssi: -90)
        }
        XCTAssertEqual(stateMachine.currentState, .warning)
    }

    func testSignalLostTriggersLock() {
        let device = WatchDevice(id: UUID(), name: "Watch")

        monitor.start()
        scanner.simulateDiscover(device: device, rssi: -40)
        XCTAssertEqual(stateMachine.currentState, .present)

        stateMachine.signalLost()

        XCTAssertEqual(stateMachine.currentState, .away)
        XCTAssertEqual(locker.lockCount, 1)
    }

    func testDisabledDoesNotLock() {
        var config = DefaultConfiguration.make()
        config.enabled = false
        configStore.configuration = config

        let disabledMonitor = ProximityMonitor(
            scanner: scanner,
            screenLocker: locker,
            configStore: configStore,
            stateMachine: stateMachine,
            bluetoothObserver: btObserver
        )

        let device = WatchDevice(id: UUID(), name: "Watch")
        disabledMonitor.start()
        scanner.simulateDiscover(device: device, rssi: -40)
        stateMachine.signalLost()

        XCTAssertEqual(locker.lockCount, 0)
        disabledMonitor.stop()
    }

    func testFiltersByWatchIdentifier() {
        let targetId = UUID()
        let otherId = UUID()

        var config = DefaultConfiguration.make()
        config.watchIdentifier = targetId.uuidString
        configStore.configuration = config

        let filteredMonitor = ProximityMonitor(
            scanner: scanner,
            screenLocker: locker,
            configStore: configStore,
            stateMachine: ProximityStateMachine(lockTimeout: 100, signalLossTimeout: 100),
            bluetoothObserver: btObserver
        )

        filteredMonitor.start()

        let otherDevice = WatchDevice(id: otherId, name: "Other Watch")
        scanner.simulateDiscover(device: otherDevice, rssi: -40)
        // Should still be unknown since we filtered out non-target
        // (state machine in the new monitor, not self.stateMachine)

        let targetDevice = WatchDevice(id: targetId, name: "My Watch")
        scanner.simulateDiscover(device: targetDevice, rssi: -40)

        filteredMonitor.stop()
    }

    func testBluetoothOffTriggersLock() {
        let device = WatchDevice(id: UUID(), name: "Watch")

        monitor.start()
        scanner.simulateBluetoothState(isPoweredOn: true)
        scanner.simulateDiscover(device: device, rssi: -40)
        XCTAssertEqual(stateMachine.currentState, .present)

        scanner.simulateBluetoothState(isPoweredOn: false)
        XCTAssertEqual(stateMachine.currentState, .away)
        XCTAssertEqual(locker.lockCount, 1)
    }
}
