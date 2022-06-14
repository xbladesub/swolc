// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swolc",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.2"),
        .package(url: "https://github.com/apple/swift-tools-support-core", from: "0.0.1"),
        .package(url: "https://github.com/xbladesub/TLogger", from: "0.0.1"),

    ],
    targets: [
        .executableTarget(
            name: "swolc",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "TLogger", package: "TLogger"),
            ]
        ),
        .testTarget(
            name: "swolcTests",
            dependencies: ["swolc"]
        ),
    ]
)
