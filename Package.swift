// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-raw",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "SwiftRaw", targets: ["SwiftRaw"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .systemLibrary(name:"Clibraw",
                pkgConfig: "libraw"),
        .target(name: "ClibrawShim", dependencies: ["Clibraw"]),
        .target(name: "SwiftRaw", dependencies: ["ClibrawShim"]),
        .testTarget(name: "SwiftRawTests",
                   dependencies: ["SwiftRaw"],
                   resources: [
                    .copy("data")
                   ])
    ])
