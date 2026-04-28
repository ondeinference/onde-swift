import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Root view
// ─────────────────────────────────────────────────────────────────────────────

struct ContentView: View {

    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(isReady: viewModel.isModelReady)

            Divider()

            ZStack {
                MessageListView(messages: viewModel.messages)

                if viewModel.isModelLoading {
                    LoadingOverlayView(progress: viewModel.loadingProgress)
                }
            }

            Divider()

            InputBarView(
                isSending: viewModel.isSending,
                isModelReady: viewModel.isModelReady,
                onSend: { text in viewModel.send(text: text) },
                onCancel: { viewModel.cancelStreaming() }
            )
        }
        .task {
            await viewModel.loadModel()
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.alertError != nil },
                set: { if !$0 { viewModel.alertError = nil } }
            ),
            presenting: viewModel.alertError
        ) { _ in
            Button("OK", role: .cancel) { viewModel.alertError = nil }
        } message: { error in
            Text(error.message)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Header
// ─────────────────────────────────────────────────────────────────────────────

private struct HeaderView: View {
    let isReady: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(isReady ? .green : .secondary)

            Text("Onde Chat")
                .font(.headline)

            Spacer()

            if isReady {
                Label("On-device", systemImage: "iphone.and.arrow.forward")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Loading overlay
// ─────────────────────────────────────────────────────────────────────────────

private struct LoadingOverlayView: View {
    let progress: String

    var body: some View {
        ZStack {
            Color(white: 1.0)
                .colorInvert()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.4)

                Text(progress)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Message list
// ─────────────────────────────────────────────────────────────────────────────

private struct MessageListView: View {
    let messages: [Message]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: messages.last?.text) { _ in
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Message bubble
// ─────────────────────────────────────────────────────────────────────────────

private struct MessageBubble: View {
    let message: Message

    private var isUser: Bool { message.role == .user }

    private var bubbleBackground: Color {
        Color.secondary.opacity(0.15)
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "You" : "Onde")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                HStack(alignment: .bottom, spacing: 6) {
                    Text(message.text.isEmpty ? " " : message.text)
                        .font(.body)
                        .foregroundStyle(isUser ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isUser ? Color.accentColor : bubbleBackground)
                        )

                    if message.isStreaming {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.bottom, 8)
                    }
                }
            }

            if !isUser { Spacer(minLength: 48) }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Input bar
// ─────────────────────────────────────────────────────────────────────────────

private struct InputBarView: View {
    let isSending: Bool
    let isModelReady: Bool
    let onSend: (String) -> Void
    let onCancel: () -> Void

    @State private var draftText: String = ""
    @FocusState private var fieldFocused: Bool

    private var inputBackground: Color {
        Color.secondary.opacity(0.15)
    }

    private var canSend: Bool {
        isModelReady && !isSending && !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $draftText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(inputBackground)
                )
                .focused($fieldFocused)
                .disabled(!isModelReady || isSending)
                .onSubmit {
                    submitIfReady()
                }

            Group {
                if isSending {
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Stop generating")
                } else {
                    Button(action: submitIfReady) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? Color.accentColor : .secondary)
                    }
                    .disabled(!canSend)
                    .accessibilityLabel("Send message")
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSending)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func submitIfReady() {
        guard canSend else { return }
        let text = draftText
        draftText = ""
        onSend(text)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview {
    ContentView()
}
