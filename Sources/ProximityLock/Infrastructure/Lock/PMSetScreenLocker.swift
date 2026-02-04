import Foundation

final class PMSetScreenLocker: ScreenLocking {

    private var lastLockTime: Date?
    private let minimumLockInterval: TimeInterval = 3.0

    func lockScreen() {
        if let lastLock = lastLockTime, Date().timeIntervalSince(lastLock) < minimumLockInterval {
            Log.lock.debug("Lock request ignored, too soon since last lock")
            return
        }

        Log.lock.info("Locking screen via pmset displaysleepnow")
        lastLockTime = Date()

        ProcessRunner.run(executablePath: "/usr/bin/pmset", arguments: ["displaysleepnow"]) { result in
            if result.exitCode == 0 {
                Log.lock.info("Screen locked successfully")
            } else {
                Log.lock.error("pmset failed: exit=\(result.exitCode), error=\(result.error)")
            }
        }
    }
}
