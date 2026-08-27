// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlockApps",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BlockApps", targets: ["BlockApps"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "BlockApps"
        ),
        .testTarget(
            name: "BlockAppsTests",
            dependencies: ["BlockApps"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
