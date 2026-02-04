import Foundation

protocol BluetoothScanningDelegate: AnyObject {
    func scanner(_ scanner: BluetoothScanning, didDiscover device: WatchDevice, rssi: Double)
    func scanner(_ scanner: BluetoothScanning, didUpdateState isPoweredOn: Bool)
}

protocol BluetoothScanning: AnyObject {
    var delegate: BluetoothScanningDelegate? { get set }
    var isScanning: Bool { get }
    func startScanning()
    func stopScanning()
    func discoveredDevices() -> [WatchDevice]
}
