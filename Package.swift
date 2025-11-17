// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftbase",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "swiftbase", targets: ["SwiftBase"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/Kitura/Swift-JWT.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.10.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.23.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftBase",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftJWT", package: "Swift-JWT"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ],
            path: "Sources/SwiftBase",
            resources: [
                .copy("Resources/Public"),
                .copy("Resources/Config")
            ]
        ),
        .testTarget(
            name: "SwiftBaseTests",
            dependencies: ["SwiftBase"],
            path: "Tests/SwiftBaseTests"
        )
    ]
)
