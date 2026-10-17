// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "piconnect",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "piconnect")
    ]
)
