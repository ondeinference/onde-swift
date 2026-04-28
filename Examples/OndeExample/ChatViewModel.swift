import Foundation
import Onde

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Message model
// ─────────────────────────────────────────────────────────────────────────────

struct Message: Identifiable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    var text: String
    /// True while the assistant is still streaming tokens for this message.
    var isStreaming: Bool = false
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - StreamChunkListener bridge
// ─────────────────────────────────────────────────────────────────────────────

/// Bridges the UniFFI callback interface to an `AsyncStream<String>`.
///
/// `StreamChunkListener.onChunk` is called from the Rust thread pool, so we
/// funnel every delta through a continuation that re-publishes on the caller's
/// structured-concurrency task.
private final class ChunkCollector: StreamChunkListener {

    private let continuation: AsyncStream<String>.Continuation

    init(continuation: AsyncStream<String>.Continuation) {
        self.continuation = continuation
    }

    /// Called by the Rust runtime for each streamed token.
    /// - Returns: `true` to keep streaming, `false` to cancel.
    func onChunk(chunk: StreamChunk) -> Bool {
        if chunk.done {
            continuation.finish()
            return false
        }
        continuation.yield(chunk.delta)
        return true
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ViewModel
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
final class ChatViewModel: ObservableObject {

    // ── Published state ───────────────────────────────────────────────────────

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isModelLoading: Bool = false
    @Published private(set) var isModelReady: Bool = false
    @Published private(set) var isSending: Bool = false
    @Published private(set) var loadingProgress: String = "Preparing model…"

    @Published var alertError: IdentifiableError? = nil

    // ── Private state ─────────────────────────────────────────────────────────

    // Lazy so the Rust/UniFFI runtime isn't initialized during
    // @StateObject construction on the UIKit event-fetch thread.
    private var engine: OndeChatEngine?
    private var streamingTask: Task<Void, Never>? = nil

    private func getOrCreateEngine() -> OndeChatEngine {
        if let existing = engine { return existing }
        let new = OndeChatEngine()
        engine = new
        return new
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Model lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    func loadModel() async {
        guard !isModelReady, !isModelLoading else { return }

        isModelLoading = true
        loadingProgress = "Downloading / loading model…"

        do {
            let elapsed = try await getOrCreateEngine().loadDefaultModel(
                systemPrompt: "You are a helpful assistant. Be concise.",
                sampling: nil
            )
            loadingProgress = String(format: "Model ready in %.1f s", elapsed)
            isModelReady = true
        } catch {
            alertError = IdentifiableError(error)
        }

        isModelLoading = false
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Sending messages
    // ─────────────────────────────────────────────────────────────────────────

    func send(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        messages.append(Message(role: .user, text: trimmed))

        streamingTask = Task {
            await streamResponse(for: trimmed)
        }
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        if let idx = messages.indices.last, messages[idx].isStreaming {
            messages[idx].isStreaming = false
        }
        isSending = false
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    private func streamResponse(for userText: String) async {
        isSending = true

        let assistantIndex = messages.count
        messages.append(Message(role: .assistant, text: "", isStreaming: true))

        // Hold onto the continuation so we can finish it from the error path.
        var storedContinuation: AsyncStream<String>.Continuation?
        let stream = AsyncStream<String> { continuation in
            storedContinuation = continuation
        }
        guard let cont = storedContinuation else { return }
        let listener = ChunkCollector(continuation: cont)

        // Run streamChatMessage off the main actor so the Rust callback thread
        // can call onChunk without deadlocking against the actor.
        let capturedEngine = self.getOrCreateEngine()
        async let _ = Task.detached(priority: .userInitiated) {
            do {
                try await streamChatMessage(
                    engine: capturedEngine,
                    message: userText,
                    listener: listener
                )
            } catch {
                cont.finish()
            }
        }.value

        for await delta in stream {
            guard !Task.isCancelled else { break }
            if assistantIndex < messages.count {
                messages[assistantIndex].text += delta
            }
        }

        if assistantIndex < messages.count {
            messages[assistantIndex].isStreaming = false
        }
        isSending = false
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Error wrapper
// ─────────────────────────────────────────────────────────────────────────────

/// Makes any `Error` `Identifiable` so it can drive a SwiftUI `.alert`.
struct IdentifiableError: Identifiable {
    let id = UUID()
    let underlying: Error

    init(_ error: Error) {
        self.underlying = error
    }

    var message: String {
        underlying.localizedDescription
    }
}
