import Foundation
import CoreBluetooth

final class CoreBluetoothScanner: NSObject, BluetoothScanning {

    weak var delegate: BluetoothScanningDelegate?

    private var centralManager: CBCentralManager!
    private var devices: [UUID: WatchDevice] = [:]
    private(set) var isScanning = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            Log.bluetooth.warning("Cannot start scanning, Bluetooth not powered on")
            return
        }

        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
        Log.bluetooth.info("Started BLE scanning")
    }

    func stopScanning() {
        guard isScanning else { return }
        centralManager.stopScan()
        isScanning = false
        Log.bluetooth.info("Stopped BLE scanning")
    }

    func discoveredDevices() -> [WatchDevice] {
        Array(devices.values)
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

        let isWatch = AppleWatchIdentifier.isPossibleAppleWatch(
            advertisementData: advertisementData,
            peripheralName: peripheral.name
        )

        guard isWatch else { return }

        let deviceId = peripheral.identifier
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String

        var device = devices[deviceId] ?? WatchDevice(id: deviceId, name: name)
        device.lastRSSI = rssiValue
        device.lastSeen = Date()
        devices[deviceId] = device

        delegate?.scanner(self, didDiscover: device, rssi: rssiValue)
    }
}
