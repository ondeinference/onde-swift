import SwiftUI
import Onde

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Root view
// ─────────────────────────────────────────────────────────────────────────────

struct ContentView: View {

    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false

    @AppStorage("onde.example.systemPrompt")
    private var systemPrompt: String = ExampleDefaults.systemPrompt

    @AppStorage("onde.example.samplingPreset")
    private var samplingPresetRawValue: String = SamplingPreset.balanced.rawValue

    private var samplingPreset: SamplingPreset {
        get { SamplingPreset(rawValue: samplingPresetRawValue) ?? .balanced }
        set { samplingPresetRawValue = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView(
                    info: viewModel.engineInfo,
                    isLoading: viewModel.isModelLoading,
                    isSending: viewModel.isSending
                )

                Divider()

                ZStack {
                    if viewModel.messages.isEmpty {
                        EmptyStateView(
                            isModelReady: viewModel.isModelReady,
                            isModelLoading: viewModel.isModelLoading,
                            loadingProgress: viewModel.loadingProgress,
                            promptSuggestions: ExampleDefaults.promptSuggestions,
                            onPromptTap: { suggestion in
                                viewModel.sendSuggestion(suggestion)
                            },
                            onRetry: {
                                Task {
                                    await viewModel.retryLoadingModel(
                                        systemPrompt: systemPrompt,
                                        samplingPreset: samplingPreset
                                    )
                                }
                            }
                        )
                    } else {
                        MessageListView(messages: viewModel.messages)
                    }

                    if viewModel.isModelLoading {
                        LoadingOverlayView(progress: viewModel.loadingProgress)
                    }
                }

                Divider()

                InputBarView(
                    isSending: viewModel.isSending,
                    isModelReady: viewModel.isModelReady,
                    placeholder: viewModel.isModelReady
                        ? "Message the on-device model…"
                        : "Waiting for model to load…",
                    onSend: { text in viewModel.send(text: text) },
                    onCancel: { viewModel.cancelStreaming() }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    if viewModel.hasMessages {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.clearConversation()
                            }
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                        .disabled(viewModel.isBusy)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.reloadModel(
                                systemPrompt: systemPrompt,
                                samplingPreset: samplingPreset
                            )
                        }
                    } label: {
                        Label("Reload model", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isBusy)

                    Button {
                        showingSettings = true
                    } label: {
                        Label("Model settings", systemImage: "slider.horizontal.3")
                    }
                    .disabled(viewModel.isBusy)
                }
            }
        }
        .task {
            await viewModel.loadModelIfNeeded(
                systemPrompt: systemPrompt,
                samplingPreset: samplingPreset
            )
        }
        .sheet(isPresented: $showingSettings) {
            ModelSettingsSheet(
                systemPrompt: systemPrompt,
                samplingPreset: samplingPreset
            ) { updatedPrompt, updatedPreset in
                systemPrompt = updatedPrompt
                samplingPresetRawValue = updatedPreset.rawValue
                Task {
                    await viewModel.applySettings(
                        systemPrompt: updatedPrompt,
                        samplingPreset: updatedPreset
                    )
                }
            }
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
    let info: EngineInfo
    let isLoading: Bool
    let isSending: Bool

    private var statusText: String {
        if isLoading {
            return "Loading"
        }
        if isSending {
            return "Generating"
        }

        switch info.status {
        case .ready:
            return "Ready"
        case .generating:
            return "Generating"
        case .loading:
            return "Loading"
        case .error:
            return "Error"
        case .unloaded:
            return "Unloaded"
        }
    }

    private var statusColor: Color {
        if isLoading {
            return .orange
        }
        if isSending {
            return .blue
        }

        switch info.status {
        case .ready:
            return .green
        case .generating:
            return .blue
        case .loading:
            return .orange
        case .error:
            return .red
        case .unloaded:
            return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Onde Chat")
                        .font(.headline)

                    Text(info.modelName ?? "Local development example")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(statusColor)
            }

            HStack(spacing: 12) {
                Label(info.approxMemory ?? "—", systemImage: "memorychip")
                Label("\(info.historyLength) turns", systemImage: "text.bubble")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
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
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)

                Text(progress)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Empty state
// ─────────────────────────────────────────────────────────────────────────────

private struct EmptyStateView: View {
    let isModelReady: Bool
    let isModelLoading: Bool
    let loadingProgress: String
    let promptSuggestions: [PromptSuggestion]
    let onPromptTap: (PromptSuggestion) -> Void
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isModelReady ? "Start chatting" : "Preparing the on-device model")
                        .font(.title3.weight(.semibold))

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if isModelReady {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Try one of these prompts")
                            .font(.headline)

                        ForEach(promptSuggestions) { suggestion in
                            Button {
                                onPromptTap(suggestion)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(suggestion.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(suggestion.prompt)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.secondary.opacity(0.10))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(loadingProgress, systemImage: isModelLoading ? "arrow.down.circle" : "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if !isModelLoading {
                            Button(action: onRetry) {
                                Label("Retry loading model", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }

    private var subtitle: String {
        if isModelReady {
            return "Your model runs locally on this device. Conversations are restored inside the example app so you can keep iterating while developing the SDK."
        }

        return "The first launch may take a while because the model has to be downloaded and loaded into memory before the chat UI becomes interactive."
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
    let placeholder: String
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
            TextField(placeholder, text: $draftText, axis: .vertical)
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
