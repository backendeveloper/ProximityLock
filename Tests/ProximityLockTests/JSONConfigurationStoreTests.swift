import XCTest
@testable import ProximityLock

final class JSONConfigurationStoreTests: XCTestCase {

    private var tempDir: String!
    private var configPath: String!
    private var store: JSONConfigurationStore!

    override func setUp() {
        super.setUp()
        tempDir = NSTemporaryDirectory() + "ProximityLockTests-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        configPath = tempDir + "/config.json"
        store = JSONConfigurationStore(filePath: configPath)
    }

    override func tearDown() {
        store.stopWatching()
        store = nil
        try? FileManager.default.removeItem(atPath: tempDir)
        super.tearDown()
    }

    func testLoadCreatesDefaultWhenFileDoesNotExist() throws {
        let config = try store.load()
        XCTAssertEqual(config.lockThreshold, -80)
        XCTAssertEqual(config.presentThreshold, -55)
        XCTAssertEqual(config.emaAlpha, 0.3)
        XCTAssertTrue(config.enabled)
        XCTAssertFalse(config.launchAtLogin)
        XCTAssertTrue(FileManager.default.fileExists(atPath: configPath))
    }

    func testSaveAndLoad() throws {
        var config = DefaultConfiguration.make()
        config.lockThreshold = -75
        config.watchName = "Test Watch"
        config.enabled = false

        try store.save(config)
        let loaded = try store.load()

        XCTAssertEqual(loaded.lockThreshold, -75)
        XCTAssertEqual(loaded.watchName, "Test Watch")
        XCTAssertFalse(loaded.enabled)
    }

    func testRoundTrip() throws {
        let original = AppConfiguration(
            watchIdentifier: "ABC-123",
            watchName: "My Watch",
            lockThreshold: -85,
            presentThreshold: -50,
            lockTimeout: 15,
            signalLossTimeout: 8,
            emaAlpha: 0.4,
            scanInterval: 3.0,
            adaptiveScanInterval: 1.5,
            enabled: false,
            launchAtLogin: true,
            lockOnBluetoothDisable: false
        )

        try store.save(original)
        let loaded = try store.load()

        XCTAssertEqual(loaded, original)
    }

    func testSaveCreatesDirectory() throws {
        let nestedPath = tempDir + "/nested/deep/config.json"
        let nestedStore = JSONConfigurationStore(filePath: nestedPath)

        try nestedStore.save(DefaultConfiguration.make())
        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedPath))
    }

    func testConfigurationPropertyUpdatedAfterSave() throws {
        var config = DefaultConfiguration.make()
        config.lockThreshold = -90
        try store.save(config)

        XCTAssertEqual(store.configuration.lockThreshold, -90)
    }

    func testConfigurationPropertyUpdatedAfterLoad() throws {
        var config = DefaultConfiguration.make()
        config.presentThreshold = -45
        try store.save(config)

        let newStore = JSONConfigurationStore(filePath: configPath)
        _ = try newStore.load()

        XCTAssertEqual(newStore.configuration.presentThreshold, -45)
    }
}
