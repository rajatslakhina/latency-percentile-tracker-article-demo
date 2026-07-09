// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LatencyKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "LatencyKit", targets: ["LatencyKit"])
    ],
    targets: [
        .target(name: "LatencyKit"),
        .testTarget(name: "LatencyKitTests", dependencies: ["LatencyKit"])
    ]
)
