import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController!
    private var proximityMonitor: ProximityMonitor!
    private var configStore: JSONConfigurationStore!
    private var launchAgentManager: LaunchAgentManager!
    private var viewModel: StatusBarViewModel!
    private var menuBuilder: MenuBuilder!

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.app.info("ProximityLock starting up")

        configStore = JSONConfigurationStore()
        do {
            _ = try configStore.load()
        } catch {
            Log.config.error("Failed to load config: \(error.localizedDescription)")
        }

        let config = configStore.configuration

        let scanner = CoreBluetoothScanner()
        let screenLocker = PMSetScreenLocker()
        let stateMachine = ProximityStateMachine(
            lockTimeout: config.lockTimeout,
            signalLossTimeout: config.signalLossTimeout
        )
        let bluetoothObserver = BluetoothStateObserver()
        launchAgentManager = LaunchAgentManager()

        proximityMonitor = ProximityMonitor(
            scanner: scanner,
            screenLocker: screenLocker,
            configStore: configStore,
            stateMachine: stateMachine,
            bluetoothObserver: bluetoothObserver
        )

        viewModel = StatusBarViewModel()
        viewModel.updateConfiguration(config)

        menuBuilder = MenuBuilder()
        menuBuilder.delegate = self

        statusBarController = StatusBarController(viewModel: viewModel, menuBuilder: menuBuilder)

        proximityMonitor.onStateChange = { [weak self] state in
            self?.viewModel.updateState(state)
        }

        proximityMonitor.onSignalUpdate = { [weak self] raw, filtered in
            guard let self else { return }
            self.viewModel.updateSignal(raw: raw, filtered: filtered)
            self.viewModel.updateDiscoveredDevices(scanner.discoveredDevices())
        }

        configStore.onConfigurationChange = { [weak self] newConfig in
            self?.viewModel.updateConfiguration(newConfig)
        }

        if config.enabled {
            proximityMonitor.start()
        }

        Log.app.info("ProximityLock ready")
    }

    func applicationWillTerminate(_ notification: Notification) {
        proximityMonitor?.stop()
        Log.app.info("ProximityLock shutting down")
    }
}

extension AppDelegate: MenuBuilderDelegate {

    func menuBuilderDidToggleEnabled(_ menuBuilder: MenuBuilder) {
        var config = configStore.configuration
        config.enabled.toggle()
        saveConfig(config)

        if config.enabled {
            proximityMonitor.start()
        } else {
            proximityMonitor.stop()
        }
    }

    func menuBuilderDidToggleLaunchAtLogin(_ menuBuilder: MenuBuilder) {
        var config = configStore.configuration
        config.launchAtLogin.toggle()
        saveConfig(config)

        do {
            if config.launchAtLogin {
                let execPath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
                try launchAgentManager.install(executablePath: execPath)
            } else {
                try launchAgentManager.uninstall()
            }
        } catch {
            Log.app.error("LaunchAgent operation failed: \(error.localizedDescription)")
        }
    }

    func menuBuilder(_ menuBuilder: MenuBuilder, didSelectWatch device: WatchDevice) {
        var config = configStore.configuration
        config.watchIdentifier = device.id.uuidString
        config.watchName = device.name
        saveConfig(config)
        Log.app.info("Selected watch: \(device.name ?? device.id.uuidString)")
    }

    func menuBuilderDidRequestOpenConfig(_ menuBuilder: MenuBuilder) {
        NSWorkspace.shared.open(URL(fileURLWithPath: Constants.Config.filePath))
    }

    func menuBuilderDidRequestQuit(_ menuBuilder: MenuBuilder) {
        NSApplication.shared.terminate(nil)
    }

    func menuBuilder(_ menuBuilder: MenuBuilder, didSetLockThreshold value: Double) {
        var config = configStore.configuration
        config.lockThreshold = value
        saveConfig(config)
    }

    func menuBuilder(_ menuBuilder: MenuBuilder, didSetPresentThreshold value: Double) {
        var config = configStore.configuration
        config.presentThreshold = value
        saveConfig(config)
    }

    private func saveConfig(_ config: AppConfiguration) {
        do {
            try configStore.save(config)
            viewModel.updateConfiguration(config)
        } catch {
            Log.config.error("Failed to save config: \(error.localizedDescription)")
        }
    }
}
