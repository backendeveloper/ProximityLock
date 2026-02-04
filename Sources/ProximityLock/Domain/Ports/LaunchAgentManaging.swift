protocol LaunchAgentManaging {
    func install(executablePath: String) throws
    func uninstall() throws
    func isInstalled() -> Bool
}
