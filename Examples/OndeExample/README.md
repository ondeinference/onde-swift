# Onde example app

A one-screen SwiftUI chat app. Loads an LLM on your iPhone and streams replies, all on-device.

## Setup

Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you don't have it:

```
brew install xcodegen
```

Generate the Xcode project and open it:

```
cd Examples/OndeExample
xcodegen generate
open OndeExample.xcodeproj
```

Set your development team under Signing & Capabilities, pick your iPhone, hit Run.

## What it does

On first launch, it downloads and loads the default model for your device (Qwen 2.5 Coder 1.5B on iPhone, 3B on Mac). After that you can chat with it. Responses stream in token by token, and there's a stop button if you want to cut it short.

## Files

| File | What's in it |
|------|-------------|
| `App.swift` | Entry point. Calls `setupInferenceEnvironment()` at launch. |
| `ContentView.swift` | The chat UI: message bubbles, text input, loading spinner. |
| `ChatViewModel.swift` | Bridges UniFFI's sync `StreamChunkListener` callback into an `AsyncStream` so SwiftUI can consume tokens on the main actor. |
| `InferenceEnvironment.swift` | Sets `HF_HOME` inside the app sandbox so HuggingFace downloads land somewhere iOS allows. |
| `project.yml` | XcodeGen spec. The `.xcodeproj` is generated from this, not checked in. |
