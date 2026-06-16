// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Yggdrasil",
    platforms: [.iOS(.v18), .macOS(.v15), .tvOS(.v17), .watchOS(.v10)],
    dependencies: [
        .package(name: "LiteratureSchema", path: "../LiteratureSchema")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Yggdrasil",
            dependencies: [
                .product(name: "LiteratureSchema", package: "LiteratureSchema")
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
