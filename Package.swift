// swift-tools-version:5.0
// https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescription.md
import PackageDescription

let package = Package(
    name: "OutlineTracking",
    platforms: [
        .macOS(.v10_11),
    ],
    products: [
        .library(name: "OutlineTracking", type: .static, targets: ["OutlineTracking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/eonil/swift-pd", .branch("master")),
    ],
    targets: [
        .target(
            name: "OutlineTracking",
            dependencies: ["PD"],
            path: "OutlineTracking"),
        .testTarget(
            name: "OutlineTrackingTest",
            dependencies: ["OutlineTracking"],
            path: "OutlineTrackingTest"),
    ]
)
