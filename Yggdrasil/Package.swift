// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Yggdrasil",
    platforms: [.iOS(.v18), .macOS(.v14), .tvOS(.v17), .watchOS(.v10)],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Yggdrasil",
            resources: [
                .process("Model.xcdatamodeld")
            ]
        )
    ]
)
