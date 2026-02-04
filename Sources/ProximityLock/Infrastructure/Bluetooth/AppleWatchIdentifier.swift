import Foundation
import CoreBluetooth

enum AppleWatchIdentifier {

    static func isPossibleAppleWatch(
        advertisementData: [String: Any],
        peripheralName: String?
    ) -> Bool {
        if let name = peripheralName ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            let lowered = name.lowercased()
            if lowered.contains("apple watch") || lowered.contains("watch") {
                return true
            }
        }

        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           manufacturerData.count >= 2 {
            let companyId = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
            if companyId == Constants.Bluetooth.appleCompanyIdentifier {
                return true
            }
        }

        return false
    }
}
