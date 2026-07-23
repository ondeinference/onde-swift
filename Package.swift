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

let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let localFrameworkPath = "OndeFramework.xcframework"
let localFrameworkAbsolutePath = packageRoot.appendingPathComponent(localFrameworkPath).path
let releaseFrameworkURL =
    "https://github.com/ondeinference/onde/releases/download/1.2.2/OndeFramework.xcframework.zip"
let releaseFrameworkChecksum =
    "3e930144fd078d1bed78ebafa22edf9763a3bc6588b0a4667fb37096ba78220b"

let ondeFrameworkTarget: Target
if FileManager.default.fileExists(atPath: localFrameworkAbsolutePath) {
    ondeFrameworkTarget = .binaryTarget(
        name: "OndeFramework",
        path: localFrameworkPath
    )
} else {
    ondeFrameworkTarget = .binaryTarget(
        name: "OndeFramework",
        url: releaseFrameworkURL,
        checksum: releaseFrameworkChecksum
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
