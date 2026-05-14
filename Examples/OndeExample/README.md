# Onde example app

A one-screen SwiftUI chat app. Loads an LLM on your iPhone and streams replies, all on-device.

## Setup

Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you don't have it:

```
brew install xcodegen
```

From the `onde-swift` repository root, build the local Onde XCFramework for iOS:

```
make ios
```

This regenerates `Sources/Onde/onde.swift` from your local Rust build in `../onde` and writes `OndeFramework.xcframework` into the package root so SwiftPM can link it.

Then generate the Xcode project and open it:

```
cd Examples/OndeExample
xcodegen generate
open OndeExample.xcodeproj
```

Set your development team under Signing & Capabilities, pick your iPhone or simulator, hit Run.

## What it does

On first launch, it downloads and loads the default model for your device (Qwen 2.5 Coder 1.5B on iPhone, 3B on Mac). After that you can chat with it.

Current example app features:

- token-by-token streaming with a stop button
- local conversation persistence between launches
- model settings sheet for system prompt + sampling preset
- toolbar actions to reload the model or clear the conversation
- prompt suggestions when the conversation is empty

## Files

| File | What's in it |
|------|-------------|
| `App.swift` | Entry point. Calls `setupInferenceEnvironment()` at launch. |
| `ContentView.swift` | The chat UI: header, empty state, message list, input bar, reload/clear actions. |
| `ChatViewModel.swift` | Bridges UniFFI streaming into Swift concurrency, manages model lifecycle, restores history, persists conversation. |
| `ExampleSupport.swift` | Prompt suggestions, sampling presets, and the settings sheet. |
| `InferenceEnvironment.swift` | Sets `HF_HOME` inside the app sandbox so HuggingFace downloads land somewhere iOS allows. |
| `project.yml` | XcodeGen spec. The `.xcodeproj` is generated from this, not checked in. |
