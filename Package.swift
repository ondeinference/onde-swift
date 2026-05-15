// swift-tools-version:6.2
import Foundation
import PackageDescription

// ─────────────────────────────────────────────────────────────────────────────
// Local development
//
// When you are working on the Onde Rust crate locally, build an XCFramework
// into this repository before opening the example app:
//
//   make ios
//   # or: make macos / make tvos / make visionos / make watchos
//
// If `./OndeFramework.xcframework` exists, this manifest uses it automatically.
// That keeps local SwiftPM and Xcode iterations fast.
//
// Distribution
//
// When the local XCFramework is absent, SwiftPM falls back to the published
// release asset attached to the matching `onde` GitHub release.
// ─────────────────────────────────────────────────────────────────────────────

let localFrameworkPath = "./OndeFramework.xcframework"
let releaseFrameworkURL =
    "https://github.com/ondeinference/onde/releases/download/1.0.0/OndeFramework.xcframework.zip"
let releaseFrameworkChecksum =
    "e50d88a657abe8d5bcc6df9422fa1bae2b2e1855209bbc4f8746ceb97f1ffd3b"

let ondeFrameworkTarget: Target
if FileManager.default.fileExists(atPath: localFrameworkPath) {
    ondeFrameworkTarget = .binaryTarget(
            name: "OndeFramework",
            url: "https://github.com/ondeinference/onde/releases/download/1.1.0/OndeFramework.xcframework.zip",
            checksum: "088997d8bdb363384940d64c80d8c357c47349ac571225692442762ea9eac300"
        )
} else {
    ondeFrameworkTarget = .binaryTarget(
            name: "OndeFramework",
            url: "https://github.com/ondeinference/onde/releases/download/1.1.0/OndeFramework.xcframework.zip",
            checksum: "088997d8bdb363384940d64c80d8c357c47349ac571225692442762ea9eac300"
        )
}

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
        ondeFrameworkTarget,
        .target(
            name: "Onde",
            dependencies: [.target(name: "OndeFramework")],
            path: "Sources/Onde"
        ),
    ]
)
