import Foundation

/// Points `HF_HOME` and `HF_HUB_CACHE` at the Onde shared App Group container
/// so downloaded models are available to every Onde-powered app on the device.
///
/// Call this once at launch, before creating an `OndeChatEngine`.
func setupInferenceEnvironment() {
    let fm = FileManager.default

    // All Onde apps use this App Group to share the HuggingFace model cache.
    // If the group isn't available (e.g. entitlement missing during development),
    // fall back to the app's own Application Support directory.
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
