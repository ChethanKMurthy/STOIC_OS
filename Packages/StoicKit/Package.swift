// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StoicKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "StoicKit", targets: ["StoicKit"])
    ],
    targets: [
        .target(
            name: "StoicKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "StoicKitTests",
            dependencies: ["StoicKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
