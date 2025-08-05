// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WuKongIMExample-Unified",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "WuKongIMExample-Unified",
            dependencies: [
                .product(name: "WuKongEasySDK", package: "WuKongEasySDK")
            ]
        )
    ]
)
