// swift-tools-version:6.2
import PackageDescription

// LOCAL DEVELOPMENT
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
// DISTRIBUTION
//
// CI updates the URL and checksum on every release.
// Do not edit them by hand. `build-swift-xcframework.yml` rewrites them when
// a new onde GitHub Release goes out.

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
            url: "https://github.com/ondeinference/onde/releases/download/1.0.0/OndeFramework.xcframework.zip",
            checksum: "e50d88a657abe8d5bcc6df9422fa1bae2b2e1855209bbc4f8746ceb97f1ffd3b"
        ),
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
    ]
)
