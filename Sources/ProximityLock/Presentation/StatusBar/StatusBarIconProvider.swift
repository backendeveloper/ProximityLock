import AppKit

enum StatusBarIconProvider {

    static func icon(for state: ProximityState) -> NSImage {
        let symbolName: String
        switch state {
        case .present:
            symbolName = "antenna.radiowaves.left.and.right"
        case .warning:
            symbolName = "antenna.radiowaves.left.and.right.slash"
        case .away:
            symbolName = "lock.fill"
        case .unknown:
            symbolName = "questionmark.circle"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: state.rawValue) {
            return image.withSymbolConfiguration(config) ?? image
        }

        return NSImage(systemSymbolName: "circle", accessibilityDescription: "fallback")!
            .withSymbolConfiguration(config)!
    }
}
