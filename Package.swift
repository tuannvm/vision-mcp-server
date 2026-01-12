// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VisionMCPServer",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Official MCP SDK for Swift (latest: 0.10.2)
        .package(
            url: "https://github.com/modelcontextprotocol/swift-sdk.git",
            from: "0.10.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "VisionMCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ],
            // Swift 6 concurrency settings
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
