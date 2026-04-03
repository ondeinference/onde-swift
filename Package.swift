// swift-tools-version:5.5
import Foundation
import PackageDescription

let package = Package(
    name: "Onde",
    platforms: [
        .iOS(.v15),
        .macOS(.v11),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "Onde", targets: ["Onde"])
    ],
    targets: [
        .binaryTarget(
            name: "OndeFramework",
            path: "./../onde/sdk/Onde/OndeFramework.xcframework",
        ),
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
    ]
)
