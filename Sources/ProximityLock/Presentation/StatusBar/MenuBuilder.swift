import AppKit

protocol MenuBuilderDelegate: AnyObject {
    func menuBuilderDidToggleEnabled(_ menuBuilder: MenuBuilder)
    func menuBuilderDidToggleLaunchAtLogin(_ menuBuilder: MenuBuilder)
    func menuBuilder(_ menuBuilder: MenuBuilder, didSelectWatch device: WatchDevice)
    func menuBuilderDidRequestOpenConfig(_ menuBuilder: MenuBuilder)
    func menuBuilderDidRequestQuit(_ menuBuilder: MenuBuilder)
    func menuBuilder(_ menuBuilder: MenuBuilder, didSetLockThreshold value: Double)
    func menuBuilder(_ menuBuilder: MenuBuilder, didSetPresentThreshold value: Double)
}

final class MenuBuilder {

    weak var delegate: MenuBuilderDelegate?

    func buildMenu(from viewModel: StatusBarViewModel) -> NSMenu {
        let menu = NSMenu()

        addSignalInfo(to: menu, viewModel: viewModel)
        menu.addItem(.separator())

        addEnabledToggle(to: menu, viewModel: viewModel)
        menu.addItem(.separator())

        addWatchSubmenu(to: menu, viewModel: viewModel)
        addThresholdSubmenu(to: menu, viewModel: viewModel)
        menu.addItem(.separator())

        addOpenConfig(to: menu)
        addLaunchAtLogin(to: menu, viewModel: viewModel)
        menu.addItem(.separator())

        addQuit(to: menu)

        return menu
    }

    private func addSignalInfo(to menu: NSMenu, viewModel: StatusBarViewModel) {
        let signalBars = String(repeating: "\u{2588}", count: viewModel.signalBarCount)
            + String(repeating: "\u{2591}", count: 5 - viewModel.signalBarCount)

        let signalItem = NSMenuItem(
            title: "Signal: \(viewModel.signalDescription)  \(signalBars)  \(viewModel.signalQuality)",
            action: nil,
            keyEquivalent: ""
        )
        signalItem.isEnabled = false
        menu.addItem(signalItem)

        let watchDisplayName = viewModel.watchName ?? "No watch selected"
        let connectionStatus = viewModel.state != .unknown ? "Connected" : "Searching"
        let watchItem = NSMenuItem(
            title: "Watch: \(watchDisplayName)  [\(connectionStatus)]",
            action: nil,
            keyEquivalent: ""
        )
        watchItem.isEnabled = false
        menu.addItem(watchItem)
    }

    private func addEnabledToggle(to menu: NSMenu, viewModel: StatusBarViewModel) {
        let item = NSMenuItem(
            title: "Enabled",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        item.target = self
        item.state = viewModel.isEnabled ? .on : .off
        menu.addItem(item)
    }

    private func addWatchSubmenu(to menu: NSMenu, viewModel: StatusBarViewModel) {
        let item = NSMenuItem(title: "Select Watch...", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        if viewModel.discoveredDevices.isEmpty {
            let scanningItem = NSMenuItem(title: "Scanning...", action: nil, keyEquivalent: "")
            scanningItem.isEnabled = false
            submenu.addItem(scanningItem)
        } else {
            for device in viewModel.discoveredDevices {
                let name = device.name ?? "Unknown (\(device.id.uuidString.prefix(8)))"
                let rssiText = device.lastRSSI.map { " (\(Int($0)) dBm)" } ?? ""
                let deviceItem = NSMenuItem(
                    title: "\(name)\(rssiText)",
                    action: #selector(selectWatch(_:)),
                    keyEquivalent: ""
                )
                deviceItem.target = self
                deviceItem.representedObject = device
                if device.id.uuidString == viewModel.selectedWatchId {
                    deviceItem.state = .on
                }
                submenu.addItem(deviceItem)
            }
        }

        item.submenu = submenu
        menu.addItem(item)
    }

    private func addThresholdSubmenu(to menu: NSMenu, viewModel: StatusBarViewModel) {
        let item = NSMenuItem(title: "Thresholds...", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let lockValues: [Double] = [-90, -85, -80, -75, -70]
        let lockItem = NSMenuItem(title: "Lock Threshold", action: nil, keyEquivalent: "")
        lockItem.isEnabled = false
        submenu.addItem(lockItem)

        for value in lockValues {
            let valueItem = NSMenuItem(
                title: "  \(Int(value)) dBm",
                action: #selector(setLockThreshold(_:)),
                keyEquivalent: ""
            )
            valueItem.target = self
            valueItem.tag = Int(value)
            submenu.addItem(valueItem)
        }

        submenu.addItem(.separator())

        let presentValues: [Double] = [-65, -60, -55, -50, -45]
        let presentItem = NSMenuItem(title: "Present Threshold", action: nil, keyEquivalent: "")
        presentItem.isEnabled = false
        submenu.addItem(presentItem)

        for value in presentValues {
            let valueItem = NSMenuItem(
                title: "  \(Int(value)) dBm",
                action: #selector(setPresentThreshold(_:)),
                keyEquivalent: ""
            )
            valueItem.target = self
            valueItem.tag = Int(value)
            submenu.addItem(valueItem)
        }

        item.submenu = submenu
        menu.addItem(item)
    }

    private func addOpenConfig(to menu: NSMenu) {
        let item = NSMenuItem(
            title: "Open Config File",
            action: #selector(openConfig),
            keyEquivalent: ""
        )
        item.target = self
        menu.addItem(item)
    }

    private func addLaunchAtLogin(to menu: NSMenu, viewModel: StatusBarViewModel) {
        let item = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        item.target = self
        item.state = viewModel.isLaunchAtLogin ? .on : .off
        menu.addItem(item)
    }

    private func addQuit(to menu: NSMenu) {
        let item = NSMenuItem(
            title: "Quit ProximityLock",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        item.target = self
        menu.addItem(item)
    }

    @objc private func toggleEnabled() {
        delegate?.menuBuilderDidToggleEnabled(self)
    }

    @objc private func toggleLaunchAtLogin() {
        delegate?.menuBuilderDidToggleLaunchAtLogin(self)
    }

    @objc private func selectWatch(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? WatchDevice else { return }
        delegate?.menuBuilder(self, didSelectWatch: device)
    }

    @objc private func openConfig() {
        delegate?.menuBuilderDidRequestOpenConfig(self)
    }

    @objc private func quit() {
        delegate?.menuBuilderDidRequestQuit(self)
    }

    @objc private func setLockThreshold(_ sender: NSMenuItem) {
        delegate?.menuBuilder(self, didSetLockThreshold: Double(sender.tag))
    }

    @objc private func setPresentThreshold(_ sender: NSMenuItem) {
        delegate?.menuBuilder(self, didSetPresentThreshold: Double(sender.tag))
    }
}
