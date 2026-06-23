// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Providers",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Providers",
            targets: ["Providers"]
        )
    ],
    dependencies: [
        .package(name: "Models", path: "../Models"),
        .package(name: "LiteratureSchema", path: "../LiteratureSchema")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Providers",
            dependencies: [
                .product(name: "Models", package: "Models"),
                .product(name: "LiteratureSchema", package: "LiteratureSchema")
            ]
        ),
        .testTarget(
            name: "ProvidersTests",
            dependencies: ["Providers"]
        ),
    ]
)
