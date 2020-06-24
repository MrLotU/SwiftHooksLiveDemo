// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyAwesomeBot",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/MrLotU/SwiftHooksDiscord.git", from: "1.0.0-alpha.1.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MyAwesomeBot",
            dependencies: [.product(name: "Discord", package: "SwiftHooksDiscord")]),
        .testTarget(
            name: "MyAwesomeBotTests",
            dependencies: ["MyAwesomeBot"]),
    ]
)
