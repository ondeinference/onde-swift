import SwiftUI

@main
struct OndeExampleApp: App {

    init() {
        // Must be called before any OndeChatEngine interaction so the Rust
        // core can find its cache directories inside the app sandbox.
        setupInferenceEnvironment()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
