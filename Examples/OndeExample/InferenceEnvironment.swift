import Foundation

/// Configures the environment variables that the Onde Rust core requires when
/// running inside an iOS/tvOS app sandbox.
///
/// Call this **before** any `OndeChatEngine` method — ideally in your `@main`
/// App struct's `init()`.
///
/// What each variable does:
/// - `HF_HOME`      – root of the HuggingFace Hub cache inside the app container
/// - `HF_HUB_CACHE` – models subdirectory (avoids the default `~/.cache` path
///                    which is unreachable in the sandbox)
/// - `TMPDIR`       – the system-provided temporary directory for the process
func setupInferenceEnvironment() {
    let fm = FileManager.default

    // Base directory for all Onde / HuggingFace data.
    // Application Support is backed up by iCloud by default; use Caches if
    // you prefer a purgeable location and are OK re-downloading models.
    let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let hfHome = appSupport.appendingPathComponent("huggingface", isDirectory: true)

    // Create the directory tree up-front so hf-hub never has to.
    let hfHubCache = hfHome.appendingPathComponent("hub", isDirectory: true)
    try? fm.createDirectory(at: hfHubCache, withIntermediateDirectories: true)

    setenv("HF_HOME",      hfHome.path,     1)
    setenv("HF_HUB_CACHE", hfHubCache.path, 1)

    // The Rust std-lib respects TMPDIR; make sure it points inside our sandbox.
    if let tmp = ProcessInfo.processInfo.environment["TMPDIR"] {
        setenv("TMPDIR", tmp, 1)   // already set by iOS — just make it explicit
    }
}
