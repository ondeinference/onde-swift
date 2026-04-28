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
            url: "https://github.com/ondeinference/onde/releases/download/1.0.0/OndeFramework.xcframework.zip",
            checksum: "e50d88a657abe8d5bcc6df9422fa1bae2b2e1855209bbc4f8746ceb97f1ffd3b"
        ),
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
        .executableTarget(
            name: "OndeExample",
            dependencies: [.target(name: "Onde")],
            path: "Examples/OndeExample"
        ),
    ]
)
