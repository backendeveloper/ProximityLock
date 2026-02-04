import Foundation

final class BluetoothStateObserver {

    var onBluetoothOff: (() -> Void)?
    var onBluetoothOn: (() -> Void)?

    private(set) var isBluetoothOn = false

    func updateState(isPoweredOn: Bool) {
        let wasOn = isBluetoothOn
        isBluetoothOn = isPoweredOn

        if wasOn && !isPoweredOn {
            Log.bluetooth.warning("Bluetooth turned off")
            onBluetoothOff?()
        } else if !wasOn && isPoweredOn {
            Log.bluetooth.info("Bluetooth turned on")
            onBluetoothOn?()
        }
    }
}
