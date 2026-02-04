import AppKit

final class StatusBarController {

    private let statusItem: NSStatusItem
    private let viewModel: StatusBarViewModel
    private let menuBuilder: MenuBuilder

    init(viewModel: StatusBarViewModel, menuBuilder: MenuBuilder) {
        self.viewModel = viewModel
        self.menuBuilder = menuBuilder
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        setupStatusItem()
        setupBindings()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = StatusBarIconProvider.icon(for: .unknown)
            button.image?.isTemplate = true
        }
        updateMenu()
    }

    private func setupBindings() {
        viewModel.onUpdate = { [weak self] in
            self?.updateUI()
        }
    }

    private func updateUI() {
        if let button = statusItem.button {
            button.image = StatusBarIconProvider.icon(for: viewModel.state)
            button.image?.isTemplate = true
        }
        updateMenu()
    }

    private func updateMenu() {
        statusItem.menu = menuBuilder.buildMenu(from: viewModel)
    }
}
