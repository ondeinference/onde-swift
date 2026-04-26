<p align="center">
  <img src="https://raw.githubusercontent.com/ondeinference/onde/main/assets/onde-inference-logo.svg" alt="Onde Inference" width="96">
</p>

<h1 align="center">Onde Inference</h1>

<p align="center">
  <strong>Run LLMs on-device from Swift, with first-class support for <a href="https://en.wikipedia.org/wiki/Apple_silicon">Apple silicon</a>.</strong>
</p>

<p align="center">
  <a href="https://swiftpackageindex.com/ondeinference/onde-swift"><img src="https://img.shields.io/badge/Swift%20Package%20Index-onde--swift-235843?style=flat-square&labelColor=17211D" alt="Swift Package Index"></a>
  <a href="https://ondeinference.com"><img src="https://img.shields.io/badge/ondeinference.com-235843?style=flat-square&labelColor=17211D" alt="Website"></a>
  <a href="https://github.com/ondeinference/onde/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-235843?style=flat-square&labelColor=17211D" alt="License"></a>
</p>

<p align="center">
  <a href="https://github.com/ondeinference/onde">Rust SDK</a> · <a href="https://central.sonatype.com/artifact/com.ondeinference/onde-inference">Kotlin Multiplatform SDK</a> · <a href="https://pub.dev/packages/onde_inference">Flutter SDK</a> · <a href="https://www.npmjs.com/package/@ondeinference/react-native">React Native SDK</a> · <a href="https://ondeinference.com">Website</a>
</p>

## Compatibility

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fondeinference%2Fonde-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ondeinference/onde-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fondeinference%2Fonde-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ondeinference/onde-swift)

---

## Installation

In Xcode, open **File → Add Package Dependencies** and enter:

```
https://github.com/ondeinference/onde-swift
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ondeinference/onde-swift", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "Onde", package: "onde-swift")
    ])
]
```

## Platforms

| Platform | Minimum | GPU Backend |
|----------|---------|-------------|
| iOS      | 15.0    | Metal       |
| macOS    | 11.0    | Metal       |
| tvOS     | 15.0    | Metal       |

## Quick Start

```swift
import Onde

let engine = OndeChatEngine()

// Load the default model for the current device:
//   iOS / tvOS → Qwen 2.5 Coder 1.5B (~941 MB)
//   macOS      → Qwen 2.5 Coder 3B (~1.93 GB)
let elapsed = try await engine.loadDefaultModel(
    systemPrompt: "You are a helpful assistant.",
    sampling: nil
)

let result = try await engine.sendMessage(message: "Hello!")
print(result.text)
```

## Streaming

```swift
import Onde

class StreamHandler: StreamChunkListener {
    func onChunk(chunk: StreamChunk) -> Bool {
        print(chunk.delta, terminator: "")
        return !chunk.done
    }
}

try await streamChatMessage(
    engine: engine,
    message: "Tell me a story.",
    listener: StreamHandler()
)
```

## One-Shot Generation

This runs inference without changing conversation history:

```swift
let result = try await engine.generate(
    messages: [userMessage(content: "Expand: a cat in space")],
    sampling: deterministicSamplingConfig()
)
```

## Sandboxed App Setup

On iOS and App Store macOS, the default `~/.cache/huggingface` path sits outside the app sandbox. This helper points `HF_HOME` at the App Group shared container (`group.com.ondeinference.apps`) so Onde-powered apps can share downloaded models. Call it once at app launch before creating an `OndeChatEngine`.

```swift
import Foundation

func setupInferenceEnvironment() {
    guard let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.ondeinference.apps"
    ) else {
        // Fall back to the app's private Application Support directory if the App Group is unavailable.
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        setupHfCache(at: appSupport)
        return
    }
    setupHfCache(at: container)
}

private func setupHfCache(at base: URL) {
    let hfHome = base.appendingPathComponent("models")
    let hfHub  = hfHome.appendingPathComponent("hub")
    try? FileManager.default.createDirectory(at: hfHub, withIntermediateDirectories: true)

    setenv("HF_HOME",      hfHome.path, 1)
    setenv("HF_HUB_CACHE", hfHub.path,  1)

    let tmp = base.appendingPathComponent("tmp")
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    setenv("TMPDIR", tmp.path, 1)
}
```

## Documentation

- [SDK Reference](https://ondeinference.com/sdk)
- [Developer Guide](https://docs.rs/onde/latest/onde/)
- [Onde Inference Rust Crate](https://github.com/ondeinference/onde)

## License

Onde is dual-licensed under **MIT** and **Apache 2.0**. You can use either one.

- [MIT License](https://github.com/ondeinference/onde/blob/main/LICENSE-MIT)
- [Apache License 2.0](https://github.com/ondeinference/onde/blob/main/LICENSE-APACHE)

© 2026 [Splitfire AB](https://splitfire.se)

---

<p align="center">
  <sub>© 2026 <a href="https://ondeinference.com">Onde Inference</a></sub>
</p>
