enum DefaultConfiguration {
    static func make() -> AppConfiguration {
        AppConfiguration(
            watchIdentifier: nil,
            watchName: nil,
            lockThreshold: Constants.Defaults.lockThreshold,
            presentThreshold: Constants.Defaults.presentThreshold,
            lockTimeout: Constants.Defaults.lockTimeout,
            signalLossTimeout: Constants.Defaults.signalLossTimeout,
            emaAlpha: Constants.Defaults.emaAlpha,
            scanInterval: Constants.Defaults.scanInterval,
            adaptiveScanInterval: Constants.Defaults.adaptiveScanInterval,
            enabled: true,
            launchAtLogin: false,
            lockOnBluetoothDisable: true
        )
    }
}
