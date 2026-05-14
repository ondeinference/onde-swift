import Foundation

/// Points `HF_HOME` and `HF_HUB_CACHE` at a writable location inside the app
/// sandbox. SDK examples prefer the shared Onde App Group so downloaded models
/// can be reused across Swift, Flutter, and React Native example apps on the
/// same device. If the group is unavailable, fall back to the app's own
/// Application Support directory.
///
/// Call this once at launch, before creating an `OndeChatEngine`.
func setupInferenceEnvironment() {
    let fm = FileManager.default

    // The Apple SDK examples share one App Group so downloaded models can be
    // reused across Swift, Flutter, and React Native sample apps. Try the
    // shared group first, then fall back to the app's private sandbox.
    let base: URL = fm.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.ondeinference.apps"
    ) ?? fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

    let hfHome     = base.appendingPathComponent("models", isDirectory: true)
    let hfHubCache = hfHome.appendingPathComponent("hub",    isDirectory: true)
    try? fm.createDirectory(at: hfHubCache, withIntermediateDirectories: true)

    setenv("HF_HOME",      hfHome.path,     1)
    setenv("HF_HUB_CACHE", hfHubCache.path, 1)

    // Make sure TMPDIR points inside the sandbox for the Rust side.
    let tmp = base.appendingPathComponent("tmp", isDirectory: true)
    try? fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    setenv("TMPDIR", tmp.path, 1)
}
