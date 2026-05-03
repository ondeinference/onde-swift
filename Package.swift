// swift-tools-version:6.2
import PackageDescription

// ─────────────────────────────────────────────────────────────────────────────
// Local development
//
// When you are working on the Onde Rust crate locally, swap the URL-based
// binary target below for a path-based one that points at your local XCFramework:
//
//     name: "OndeFramework"
//     path: "./../onde/sdk/Onde/OndeFramework.xcframework"
//
// Build the framework first:
//   cd onde && .github/scripts/build-swift-xcframework.sh
//
// Distribution
//
// CI updates the URL and checksum on every release.
// Do not edit them by hand. `build-swift-xcframework.yml` rewrites them when
// a new onde GitHub Release goes out.
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
