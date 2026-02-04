import Foundation

final class JSONConfigurationStore: ConfigurationStore {

    private let filePath: String
    private let fileManager: FileManager
    private var fileWatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private(set) var configuration: AppConfiguration

    var onConfigurationChange: ((AppConfiguration) -> Void)?

    init(filePath: String = Constants.Config.filePath, fileManager: FileManager = .default) {
        self.filePath = filePath
        self.fileManager = fileManager
        self.configuration = DefaultConfiguration.make()
    }

    func save(_ configuration: AppConfiguration) throws {
        let directory = (filePath as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: directory) {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(configuration)
        try data.write(to: URL(fileURLWithPath: filePath))

        self.configuration = configuration
        Log.config.info("Configuration saved to \(self.filePath)")
    }

    func load() throws -> AppConfiguration {
        guard fileManager.fileExists(atPath: filePath) else {
            let defaultConfig = DefaultConfiguration.make()
            try save(defaultConfig)
            return defaultConfig
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let decoder = JSONDecoder()
        let loaded = try decoder.decode(AppConfiguration.self, from: data)
        self.configuration = loaded
        Log.config.info("Configuration loaded from \(self.filePath)")
        return loaded
    }

    func startWatching() {
        stopWatching()

        guard fileManager.fileExists(atPath: filePath) else { return }

        fileDescriptor = open(filePath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            Log.config.error("Failed to open file for watching: \(self.filePath)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.handleFileChange()
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        source.resume()
        fileWatchSource = source
        Log.config.info("Started watching configuration file")
    }

    func stopWatching() {
        fileWatchSource?.cancel()
        fileWatchSource = nil
    }

    private func handleFileChange() {
        do {
            let newConfig = try load()
            if newConfig != configuration {
                configuration = newConfig
                onConfigurationChange?(newConfig)
                Log.config.info("Configuration changed externally, reloaded")
            }
        } catch {
            Log.config.error("Failed to reload configuration: \(error.localizedDescription)")
        }
    }

    deinit {
        stopWatching()
    }
}
