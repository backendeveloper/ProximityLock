// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ProximityLock",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ProximityLock",
            dependencies: [],
            path: "Sources/ProximityLock",
            resources: [
                .copy("../../Resources/Info.plist")
            ]
        ),
        .testTarget(
            name: "ProximityLockTests",
            dependencies: ["ProximityLock"],
            path: "Tests/ProximityLockTests"
        )
    ]
)
