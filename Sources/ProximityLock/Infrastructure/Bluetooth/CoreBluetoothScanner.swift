import Foundation
import CoreBluetooth

final class CoreBluetoothScanner: NSObject, BluetoothScanning {

    weak var delegate: BluetoothScanningDelegate?
    var trackedDeviceIdentifier: UUID?

    private var centralManager: CBCentralManager!
    private var devices: [UUID: WatchDevice] = [:]
    private(set) var isScanning = false
    private var scanRestartTimer: Timer?
    private var scanInterval: TimeInterval = 2.0

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            Log.bluetooth.warning("Cannot start scanning, Bluetooth not powered on")
            return
        }

        performScan()
        startScanRestartTimer()
        isScanning = true
        Log.bluetooth.info("Started BLE scanning with periodic restart")
    }

    func stopScanning() {
        guard isScanning else { return }
        scanRestartTimer?.invalidate()
        scanRestartTimer = nil
        centralManager.stopScan()
        isScanning = false
        Log.bluetooth.info("Stopped BLE scanning")
    }

    func discoveredDevices() -> [WatchDevice] {
        Array(devices.values)
    }

    func updateScanInterval(_ interval: TimeInterval) {
        scanInterval = interval
        if isScanning {
            startScanRestartTimer()
        }
    }

    private func performScan() {
        centralManager.stopScan()
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    private func startScanRestartTimer() {
        scanRestartTimer?.invalidate()
        scanRestartTimer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            guard let self, self.isScanning else { return }
            self.performScan()
        }
    }
}

extension CoreBluetoothScanner: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let isPoweredOn = central.state == .poweredOn
        Log.bluetooth.info("Bluetooth state: \(central.state.rawValue), poweredOn: \(isPoweredOn)")
        delegate?.scanner(self, didUpdateState: isPoweredOn)

        if isPoweredOn && !isScanning {
            startScanning()
        } else if !isPoweredOn {
            scanRestartTimer?.invalidate()
            scanRestartTimer = nil
            isScanning = false
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssiValue = RSSI.doubleValue
        guard rssiValue < 0, rssiValue > -100 else { return }

        let deviceId = peripheral.identifier
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String

        var device = devices[deviceId] ?? WatchDevice(id: deviceId, name: name)
        device.lastRSSI = rssiValue
        device.lastSeen = Date()
        devices[deviceId] = device

        delegate?.scanner(self, didDiscover: device, rssi: rssiValue)
    }
}
