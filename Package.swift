// swift-tools-version:6.2
import PackageDescription

// ─────────────────────────────────────────────────────────────────────────────
// Local development
//
// When you are working on the Onde Rust crate locally, build a path-based
// XCFramework into this repository before opening the example app:
//
//   make ios
//   # or: make macos / make tvos / make visionos / make watchos
//
// The generated framework lives at:
//   ./OndeFramework.xcframework
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
            path: "./OndeFramework.xcframework"
        ),
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
    ]
)
