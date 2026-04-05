// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LoudMic",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../mac-app-kit"),
    ],
    targets: [
        .executableTarget(
            name: "LoudMic",
            dependencies: [.product(name: "MacAppKit", package: "mac-app-kit")],
            path: "app/LoudMic",
            exclude: ["Info.plist"]
        )
    ]
)
