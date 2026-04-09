// swift-tools-version:6.2
import PackageDescription

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL DEVELOPMENT
//
// When working on the Onde Rust crate locally, swap the url-based binary
// target below to a path-based one pointing at your local XCFramework:
//
//     name: "OndeFramework"
//     path: "./../onde/sdk/Onde/OndeFramework.xcframework"
//
// Run the build script first to produce the framework:
//   cd onde && .github/scripts/build-swift-xcframework.sh
//
// DISTRIBUTION
//
// The url + checksum below are updated automatically by CI on every release.
// Do not edit them by hand — they are rewritten by build-swift-xcframework.yml
// when a new onde GitHub Release is published.
// ─────────────────────────────────────────────────────────────────────────────

let package = Package(
    name: "Onde",
    platforms: [
        .iOS(.v15),
        .macOS(.v11),
        .tvOS(.v15),
        .visionOS(.v26),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "Onde", targets: ["Onde"])
    ],
    targets: [
        .binaryTarget(
            name: "OndeFramework",
            url: "https://github.com/ondeinference/onde/releases/download/0.1.3/OndeFramework.xcframework.zip",
            checksum: "87f57dce37e382782206c29d2998078894b1f29e64d42a6005d86c36f2b686b6"
        ),
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
    ]
)
