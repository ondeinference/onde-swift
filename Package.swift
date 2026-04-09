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
            url: "https://github.com/ondeinference/onde/releases/download/0.1.2/OndeFramework.xcframework.zip",
            checksum: "0a4d312d6f312e44229f3b58d7e9f0b15b8adc397947b7178601527a478bb7c0"
        ),
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
    ]
)
