// swift-tools-version:6.2
import PackageDescription

// ─────────────────────────────────────────────────────────────────────────────
// Local development
//
// Working on the Onde Rust crate locally? Swap the url-based binary target
// below for a path-based one pointing at your local XCFramework:
//
//     name: "OndeFramework"
//     path: "./../onde/sdk/Onde/OndeFramework.xcframework"
//
// Build the framework first:
//   cd onde && .github/scripts/build-swift-xcframework.sh
//
// Distribution
//
// The url and checksum below are rewritten by CI (build-swift-xcframework.yml)
// each time a new onde GitHub Release goes out. Don't edit them by hand.
// ─────────────────────────────────────────────────────────────────────────────

let package = Package(
    name: "Onde",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
        .tvOS(.v16),
        .visionOS(.v1),
        .watchOS(.v9),
    ],
    products: [
        .library(name: "Onde", targets: ["Onde"])
    ],
    targets: [
        .binaryTarget(
            name: "OndeFramework",
            path: "./../onde/sdk/Onde/OndeFramework.xcframework"
        ),
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
    ]
)
