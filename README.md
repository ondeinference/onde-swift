<p align="center">
  <img src="https://raw.githubusercontent.com/ondeinference/onde/main/assets/onde-inference-logo.svg" alt="Onde Inference" width="96">
</p>

<h1 align="center">Onde</h1>

<p align="center">
  <strong>On-device LLM inference for Swift — optimized for <a href="https://en.wikipedia.org/wiki/Apple_silicon">Apple silicon</a>.</strong>
</p>

<p align="center">
  <a href="https://swiftpackageindex.com/ondeinference/onde-swift"><img src="https://img.shields.io/badge/Swift%20Package%20Index-onde--swift-235843?style=flat-square&labelColor=17211D" alt="Swift Package Index"></a>
  <a href="https://ondeinference.com"><img src="https://img.shields.io/badge/ondeinference.com-235843?style=flat-square&labelColor=17211D" alt="Website"></a>
  <a href="https://apps.apple.com/se/developer/splitfire-ab/id1831430993"><img src="https://img.shields.io/badge/App%20Store-live-235843?style=flat-square&labelColor=17211D" alt="App Store"></a>
</p>

## Compatibility

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fondeinference%2Fonde-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ondeinference/onde-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fondeinference%2Fonde-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ondeinference/onde-swift)

---

## Installation

In Xcode: **File → Add Package Dependencies** and enter:

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

// Load the platform-appropriate default model:
//   iOS / tvOS → Qwen 2.5 1.5B (~941 MB)
//   macOS      → Qwen 2.5 3B   (~1.93 GB)
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

Run inference without modifying conversation history:

```swift
let result = try await engine.generate(
    messages: [userMessage(content: "Expand: a cat in space")],
    sampling: deterministicSamplingConfig()
)
```

## Sandboxed App Setup

On iOS and App Store macOS, configure the HuggingFace cache directory before any inference call:

```swift
import Foundation

func setupInferenceEnvironment() {
    let appSupport = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

    let hfHome = appSupport.appendingPathComponent("huggingface")
    let hfHub  = hfHome.appendingPathComponent("hub")
    try? FileManager.default.createDirectory(at: hfHub, withIntermediateDirectories: true)

    setenv("HF_HOME",      hfHome.path, 1)
    setenv("HF_HUB_CACHE", hfHub.path,  1)

    let tmp = appSupport.appendingPathComponent("tmp")
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    setenv("TMPDIR", tmp.path, 1)
}
```

Call this once at app launch, before creating an `OndeChatEngine`.

## Documentation

- [SDK Reference](https://ondeinference.com/sdk)
- [Developer Guide](https://docs.rs/onde/latest/onde/)
- [Onde Inference Rust Crate](https://github.com/ondeinference/onde)

## License

[MIT](LICENSE)

---

<p align="center">
  <sub>© 2026 <a href="https://ondeinference.com">Onde Inference</a></sub>
</p>
