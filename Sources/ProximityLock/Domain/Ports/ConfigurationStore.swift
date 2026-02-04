protocol ConfigurationStore: AnyObject {
    var configuration: AppConfiguration { get }
    func save(_ configuration: AppConfiguration) throws
    func load() throws -> AppConfiguration
    var onConfigurationChange: ((AppConfiguration) -> Void)? { get set }
    func startWatching()
    func stopWatching()
}
