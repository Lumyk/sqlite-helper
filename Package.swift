// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sqlite-helper",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "sqlite-helper",
            targets: ["sqlite-helper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.11.5"),
        .package(url: "https://github.com/lumyk/apollo-mapper.git", .exact("0.0.7")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "sqlite-helper",
            dependencies: ["SQLite", "apollo-mapper"]),
        .testTarget(
            name: "sqlite-helperTests",
            dependencies: ["sqlite-helper"]),
    ]
)
